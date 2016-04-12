module Dora
  module Protocol
    module Media
      module Videos

        def get_extension_from_mime(mime)
          EXTENSIONS[mime.to_sym]
        end

        EXTENSIONS = {
            'audio/3gp':       '3gp',
            'audio/x-caf':     'caf',
            'audio/wav':       'wav',
            'audio/mpeg':      'mp3',
            'audio/mpeg3':     'mp3',
            'audio/x-mpeg-3':  'mp3',
            'audio/x-ms-wma':  'wma',
            'audio/ogg':       'ogg',
            'audio/aiff':      'aif',
            'audio/x-aiff':    'aif',
            'audio/aac':       'aac',
            'audio/mp4':       'm4a',
            'image/jpeg':      'jpg',
            'image/gif':       'gif',
            'image/png':       'png',
            'video/3gpp':      '3gp',
            'video/mp4':       'mp4',
            'video/quicktime': 'mov',
            'video/avi':       'avi',
            'video/msvideo':   'avi',
            'video/x-msvideo': 'avi'
        }

        private

        def create_video_icon(file) #TODO
          if check_ffmpeg
            #generate thumbnail
            preview = sys_get_temp_dir() + '/' + Digest::MD5.hexdigest(file) + '.jpg'
            unlink(preview)

            #capture video preview
            command = "ffmpeg -i \"" + file + "\" -f mjpeg -ss 00:00:01 -vframes 1 \"" + preview + "\""
            exec(command)

            create_icon_gd(preview)
          else
            video_path = File.join(Dora.data, MEDIA_FOLDER + '/video_thumbnail.txt')
            video_thumbnail = File.open(video_path).read
            base64_decode(video_thumbnail)
          end
        end

        def check_ffmpeg()
          #check if ffmpeg is installed.
          output = []
          return_value = false
          exec('ffmpeg -version', output, return_value)
          return_value === 0
        end

        def get_mime(file)
          image = MiniMagick::Image.new(file)
          image.mime_type
        end

      end
    end
  end
end