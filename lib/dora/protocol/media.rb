require 'dora/connector'

require 'mini_magick'
require 'open-uri'
require 'uri'
require 'net/http'

require 'dora/protocol/media/uploader'
require 'dora/protocol/media/images'
require 'dora/protocol/media/videos'

module Dora
  module Protocol
    module Process
      module Media
        include Images
        include Videos

        def media_queue
          @media_queue ||= {}
        end

        def media_file_info
          @media_file_info ||= {}
        end

        def profile_image(jid, file_path)
          id = create_iq_id
          puts "profile_image: #{id}"
          image = preprocess_profile_picture(file_path)
          preview = create_icon(file_path, 96)

          picture = Node.new('picture', {type: 'image'}, nil, image)
          preview = Node.new('picture', {type: 'preview'}, nil, preview)
          node = IqNode.new(id, jid, 'set', 'w:profile:picture', [picture, preview])

          send_node(node)
          wait_for_server(id)
        end

        def send_image(to, file_path, options={})
          f_size = options[:size] ? options[:size] : 0
          f_hash = options[:hash] ? options[:hash] : ''
          if f_size == 0 || f_hash == ''
            allowed_extensions = %w(jpg jpeg gif png)
            size = 5 * 1024 * 1024
            send_check_and_send_media(file_path, size, to, 'image', allowed_extensions, options[:store_url_media], options[:caption])
          else
            send_request_file_upload(f_hash, 'image', f_size, file_path, to, caption);
          end
        end

        def send_video(to, file_path, store_url_media = false, f_size = 0, f_hash = '', caption = '')
          if f_size == 0 || f_hash == ''
            allowed_extensions = %w(3gp mp4 mov avi)
            size = 20 * 1024 * 1024; # Easy way to set maximum file size for this media type.
            # Return message ID. Make pull request for this.
            send_check_and_send_media(file_path, size, to, 'video', allowed_extensions, store_url_media, caption)
          else
            # Return message ID. Make pull request for this.
            send_request_file_upload(f_hash, 'video', f_size, file_path, to, caption)
          end
        end

        private

        def send_check_and_send_media(file_path, max_size, to, type, allowed_extensions, store_url_media, caption = '')
          if get_media_file(file_path, max_size)
            if allowed_extensions.include?(media_file_info[:file_extension].downcase)
              media = open(media_file_info[:file_path]).read
              base_64_hash = Base64.strict_encode64(Digest::SHA256.digest(media))
              id = send_request_file_upload(base_64_hash, type, media_file_info[:file_size], media_file_info[:file_path], to, caption)
              process_temp_media_file(store_url_media)
              id
            else
              process_temp_media_file(store_url_media)
              nil
            end
          else
            nil
          end
        end

        def get_media_file(file_path, max_size_bytes = 5242880)
          mime_type = valid_uri?(file_path)
          if mime_type

            media = open(file_path).read
            media_file_info = { url: file_path, file_size: media.length }

            if media_file_info[:file_size] < max_size_bytes
              media_file_info[:file_path] = File.join(Dora.data, MEDIA_FOLDER + '/' + unique_media_string)
              File.open(media_file_info[:file_path], 'w') { |file| file.write(media) }
              media_file_info[:file_mime_type] = mime_type
              mime = MIME::Types[media_file_info[:file_mime_type]].first
              media_file_info[:file_extension] = mime.extensions.first
              true
            else
              false
            end
          elsif File.exist?(file_path)
            #Local file
            media_file_info[:file_size] = File.size(file_path)
            if media_file_info[:file_size] < max_size_bytes
              media_file_info[:file_path] = file_path
              media_file_info[:file_mime_type] = get_mime(file_path)
              mime_type = MIME::Types[media_file_info[:file_mime_type]].first
              media_file_info[:file_extension] = mime_type.extensions.first
              true
            else
              false
            end
          else
            false
          end
        end

        def valid_uri?(url)
          url_regex = Regexp.new("((https?|ftp|file):((//)|(\\\\))+[\w\d:\#@%/;$()~_?\+-=\\\\.&]*)")
          regex = url =~ url_regex ? true : false

          if regex
            uri = URI(url)
            request = ::Net::HTTP.new uri.host
            response = request.request_head uri.path
            response.code.to_i == 200 && response.header['Content-Type']
          else
            false
          end
        end

        def unique_media_string
          filename = generate_wha_string
          while File.exist?(filename)
            filename = generate_wha_string
          end
          filename
        end

        def generate_wha_string
          "WHA#{SecureRandom.urlsafe_base64}"
        end

        def process_temp_media_file(store_url_media)
          if media_file_info.has_key? :url
            if store_url_media
              if File.file?(media_file_info[:file_path])
                File.rename(media_file_info[:file_path], store_url_media[:file_path]+'.'+store_url_media[:file_extension]);
              end
            else
              if File.file?(media_file_info[:file_path])
                File.unlink(media_file_info[:file_path])
              end
            end
          end
        end

        def send_request_file_upload(b64hash, type, size, file_path, to, caption = '')
          id = create_iq_id

          if to.is_a? Array
            to = to.to_jid
          end

          media_node = Node.new('media', {hash: b64hash, type: type, size: size})
          node = IqNode.new(id, WHATSAPP_SERVER, 'set', 'w:m', [media_node])

          #add to queue
          message_id = create_msg_id
          media_queue[id] = {
              message_node: node,
              file_path: file_path,
              to: to,
              message_id: message_id,
              caption: caption
          }
          send_node(node)
          wait_for_server(id)

          # Return message ID. Make pull request for this.
          message_id
        end

        protected

        def process_upload_response(node, id)
          node_id = node.attributes['id']
          message_node = media_queue[node_id]
          if message_node.nil?
            #message not found, can't send!
            return false
          end

          duplicate = node.get_child('duplicate')
          if duplicate.nil?
            #upload new file
            json = Uploader.push_file(node, message_node, media_file_info, id)
            if json.nil?
              #failed upload
              return false
            end
            url = json['url']
            file_size = json['size']
            file_type = json['type']
            file_name = json['name']
          else
            #file already on whatsapp servers
            url = duplicate.attributes['url']
            file_size = duplicate.attributes['size']
            file_type = duplicate.attributes['type']
            file_name = url.split('/').last
          end

          media_attributes = {type: file_type, url: url, encoding: 'raw', file: file_name, size: file_size}
          if message_node[:caption] != ''
            media_attributes[:caption] = message_node[:caption]
          end

          file_path = message_node[:file_path]
          to = message_node[:to]

          case file_type
            when 'image'
              caption = message_node[:caption]
              icon = create_icon(file_path)
            when 'video'
              caption = message_node[:caption]
              icon = create_video_icon(file_path)
            else
              caption = ''
              icon = ''
          end
          #Retrieve Message ID
          message_id = message_node[:message_id]
          media_node = Node.new('media', media_attributes, nil, icon)
          if to.is_a?(Array)
            send_broadcast(to, media_node, 'media')
          else
            send_message_node(to, media_node, message_id)
          end
          true
        end

      end
    end
  end
end