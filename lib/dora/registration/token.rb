require 'digest/md5'
require 'base64'
require 'dora/registration/utils'

module Dora
  module Registration
    # Token class to generate token for connect with WhatsApp
    class Token
      RELEASE_TIME = '1452554789539'

      def self.update_release_time(data)
        ver = data['e']
        if WHATSAPP_VER != ver
          release_time = data['h']

          #Update RELEASE TIME in execution
          send(:remove_const, 'RELEASE_TIME') if const_defined?('RELEASE_TIME')
          const_set('RELEASE_TIME', release_time)

          # RELEASE_TIME = 9999999999999
          # Update file
          regexp = /RELEASE_TIME = \'\d{13}\'/
          write = "RELEASE_TIME = '#{release_time}'"
          Utils.file_edit(File.expand_path('../chat_api/lib/dora/registration/token.rb'), regexp, write)
        end
      end

      def initialize(phone)
        @phone = phone
      end

      def generate(platform='Nokia')
        send("generate_#{platform.downcase}")
      end

      private

      def generate_android
        signature  = 'MIIDMjCCAvCgAwIBAgIETCU2pDALBgcqhkjOOAQDBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFDASBgNVBAcTC1NhbnRhIENsYXJhMRYwFAYDVQQKEw1XaGF0c0FwcCBJbmMuMRQwEgYDVQQLEwtFbmdpbmVlcmluZzEUMBIGA1UEAxMLQnJpYW4gQWN0b24wHhcNMTAwNjI1MjMwNzE2WhcNNDQwMjE1MjMwNzE2WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEUMBIGA1UEBxMLU2FudGEgQ2xhcmExFjAUBgNVBAoTDVdoYXRzQXBwIEluYy4xFDASBgNVBAsTC0VuZ2luZWVyaW5nMRQwEgYDVQQDEwtCcmlhbiBBY3RvbjCCAbgwggEsBgcqhkjOOAQBMIIBHwKBgQD9f1OBHXUSKVLfSpwu7OTn9hG3UjzvRADDHj+AtlEmaUVdQCJR+1k9jVj6v8X1ujD2y5tVbNeBO4AdNG/yZmC3a5lQpaSfn+gEexAiwk+7qdf+t8Yb+DtX58aophUPBPuD9tPFHsMCNVQTWhaRMvZ1864rYdcq7/IiAxmd0UgBxwIVAJdgUI8VIwvMspK5gqLrhAvwWBz1AoGBAPfhoIXWmz3ey7yrXDa4V7l5lK+7+jrqgvlXTAs9B4JnUVlXjrrUWU/mcQcQgYC0SRZxI+hMKBYTt88JMozIpuE8FnqLVHyNKOCjrh4rs6Z1kW6jfwv6ITVi8ftiegEkO8yk8b6oUZCJqIPf4VrlnwaSi2ZegHtVJWQBTDv+z0kqA4GFAAKBgQDRGYtLgWh7zyRtQainJfCpiaUbzjJuhMgo4fVWZIvXHaSHBU1t5w//S0lDK2hiqkj8KpMWGywVov9eZxZy37V26dEqr/c2m5qZ0E+ynSu7sqUD7kGx/zeIcGT0H+KAVgkGNQCo5Uc0koLRWYHNtYoIvt5R3X6YZylbPftF/8ayWTALBgcqhkjOOAQDBQADLwAwLAIUAKYCp0d6z4QQdyN74JDfQ2WCyi8CFDUM4CaNB+ceVXdKtOrNTQcc0e+t'
        md5_key = '7UDPOXwpiLBvEjT8uNwsuA==' # 2.12.440

        key  = Base64.strict_decode64('eQV5aq/Cg63Gsq1sshN9T3gh+UUp0wIw0xgHYT1bnCjEqOJQKCRrWxdAe2yvsDeCJL+Y4G3PRD2HUF7oUgiGo8vGlNJOaux26k+A2F3hj8A=')
        data = Base64.strict_decode64(signature) + Base64.strict_decode64(md5_key) + @phone

        backslashes = 0x5C.chr * 64
        sixes = 0x36.chr * 64
        64.times do | time |
          key_time = key[time].ord
          backslashes[time] = (backslashes[time].ord ^ key_time).chr
          sixes[time] = (sixes[time].ord ^ key_time).chr
        end

        output = Digest::SHA1.digest(backslashes + Digest::SHA1.digest(sixes + data))

        Base64.strict_encode64(output)
      end

      def generate_nokia
        md5_key = "PdA2DJyKoUrwLw1Bg6EIhzh502dF9noR9uFCllGk#{RELEASE_TIME}#{@phone}"
        Digest::MD5.hexdigest(md5_key)
      end
    end
  end
end
