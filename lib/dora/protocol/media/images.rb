module Dora
  module Protocol
    module Media
      module Images
        def preprocess_profile_picture(path)
          resize(path, 639)
        end

        def create_icon(file_path, size = 100)
          if File.exist?(file_path) && File.readable?(file_path)
            resize(file_path, size)
          else
            gift_path = File.join(Dora.data, MEDIA_FOLDER + '/gift_thumbnail.txt')
            gift_thumbnail = File.open(gift_path).read
            Base64.strict_decode64(gift_thumbnail)
          end
        end

        def resize(file_path, size)
          image = MiniMagick::Image.open(file_path)
          image_resize = image.resize "#{size.to_s}x#{size.to_s}\!"
          puts 'image: ' + image_resize.dimensions.to_s
          image_resize.to_blob
        end

        def get_mime(file)
          image = MiniMagick::Image.new(file)
          image.mime_type
        end

      end
    end
  end
end