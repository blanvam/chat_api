require 'net/http'

module Dora
  module Protocol
    class Uploader
      def self.push_file(upload_response_node, message_container, media_file, self_jid)
        url       = upload_response_node.get_child('media').attributes['url']
        file_path = message_container[:file_path]
        to        = message_container[:to]
        get_post_string(file_path, url, media_file, to, self_jid)
      end

      private

      def self.get_post_string(file_path, url, media_file, to, from)
        host = URI(url).host

        crypto_name = Digest::MD5.hexdigest(file_path) + '.' + media_file[:file_extension]
        boundary = 'zzXXzzYYzzXXzzQQ'

        if to.is_a? Array
            to = to.split(',')
        end

        h_baos = '--' + boundary + "\r\n"
        h_baos += "Content-Disposition: form-data; name=\"to\"\r\n\r\n"
        h_baos += to + "\r\n"
        h_baos += '--' + boundary + "\r\n"
        h_baos += "Content-Disposition: form-data; name=\"from\"\r\n\r\n"
        h_baos += from + "\r\n"
        h_baos += '--' + boundary + "\r\n"
        h_baos += "Content-Disposition: form-data; name=\"file\"; filename=\"" + crypto_name + "\"\r\n"
        h_baos += 'Content-Type: ' + media_file[:file_mime_type] + "\r\n\r\n"

        f_baos = "\r\n--" + boundary + "--\r\n"

        content_length = h_baos.length + f_baos.length + media_file[:file_size]

        post = 'POST ' + url + "\r\n"
        post += 'Content-Type: multipart/form-data; boundary=' + boundary + "\r\n"
        post += 'Host: ' + host + "\r\n"
        post += 'User-Agent: ' + WHATSAPP_USER_AGENT + "\r\n"
        post += 'Content-Length: ' + content_length.to_s + "\r\n\r\n"

        send_data(host, post, h_baos, file_path, media_file, f_baos)
      end

      def self.send_data(host, post, head, file_path, media_file, tail)
        sock = TCPSocket.new(host, 443)
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_PEER)
        socket = OpenSSL::SSL::SSLSocket.new(sock, ctx).tap do |socket|
          socket.sync_close = true
          socket.connect
        end

        socket.write(post)
        socket.write(head)

        #write file data
        buf = 1024
        total_read = 0
        file = File.open(file_path, 'r')
        while total_read < media_file[:file_size] do
          buff = file.read(buf)
          if media_file[:file_size] - total_read < buf
            buf = media_file[:file_size] - total_read
          end
          socket.write(buff)
          total_read += buf
        end
        socket.write(tail)
        sleep(1)

        data = socket.read
        socket.close

        array_data = data.split("\n")

        json = JSON.parse(array_data[6]) rescue nil
        if json.nil?
          false
        else
          json
        end
      end

    end
  end
end
