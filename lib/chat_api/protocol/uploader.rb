module Dora
  module Protocol
    class Uploader

      def self.push_file(upload_response_node, message_container, media_file, self_jid)
        url       = upload_response_node.get_child('media').attributes['url']
        file_path = message_container['filePath']
        to        = media_file['to']
        return self::get_post_string(file_path, url, media_file, to, self_jid)
      end

      private

      def self.get_post_string(file_path, url, media_file, to, from)
        # TODO
      end

      def self.send_data
        # TODO
      end
    end
  end
end
