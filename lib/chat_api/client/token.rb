require 'digest/md5'
require 'base64'

module Dora
  class Client
    class Token
      RELEASE_TIME = '1439921717185'

      def Token.generate_request_token(phone, platform='Nokia')
        case platform
          when 'Android'
            signature  = 'MIIDMjCCAvCgAwIBAgIETCU2pDALBgcqhkjOOAQDBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFDASBgNVBAcTC1NhbnRhIENsYXJhMRYwFAYDVQQKEw1XaGF0c0FwcCBJbmMuMRQwEgYDVQQLEwtFbmdpbmVlcmluZzEUMBIGA1UEAxMLQnJpYW4gQWN0b24wHhcNMTAwNjI1MjMwNzE2WhcNNDQwMjE1MjMwNzE2WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEUMBIGA1UEBxMLU2FudGEgQ2xhcmExFjAUBgNVBAoTDVdoYXRzQXBwIEluYy4xFDASBgNVBAsTC0VuZ2luZWVyaW5nMRQwEgYDVQQDEwtCcmlhbiBBY3RvbjCCAbgwggEsBgcqhkjOOAQBMIIBHwKBgQD9f1OBHXUSKVLfSpwu7OTn9hG3UjzvRADDHj+AtlEmaUVdQCJR+1k9jVj6v8X1ujD2y5tVbNeBO4AdNG/yZmC3a5lQpaSfn+gEexAiwk+7qdf+t8Yb+DtX58aophUPBPuD9tPFHsMCNVQTWhaRMvZ1864rYdcq7/IiAxmd0UgBxwIVAJdgUI8VIwvMspK5gqLrhAvwWBz1AoGBAPfhoIXWmz3ey7yrXDa4V7l5lK+7+jrqgvlXTAs9B4JnUVlXjrrUWU/mcQcQgYC0SRZxI+hMKBYTt88JMozIpuE8FnqLVHyNKOCjrh4rs6Z1kW6jfwv6ITVi8ftiegEkO8yk8b6oUZCJqIPf4VrlnwaSi2ZegHtVJWQBTDv+z0kqA4GFAAKBgQDRGYtLgWh7zyRtQainJfCpiaUbzjJuhMgo4fVWZIvXHaSHBU1t5w//S0lDK2hiqkj8KpMWGywVov9eZxZy37V26dEqr/c2m5qZ0E+ynSu7sqUD7kGx/zeIcGT0H+KAVgkGNQCo5Uc0koLRWYHNtYoIvt5R3X6YZylbPftF/8ayWTALBgcqhkjOOAQDBQADLwAwLAIUAKYCp0d6z4QQdyN74JDfQ2WCyi8CFDUM4CaNB+ceVXdKtOrNTQcc0e+t'
            classes_md5 = 'PERSVxyRE03RRwC3TrED+g==' # 2.12.291

            key  = Base64.strict_decode64('/UIGKU1FVQa+ATM2A0za7G2KI9S/CwPYjgAbc67v7ep42eO/WeTLx1lb1cHwxpsEgF4+PmYpLd2YpGUdX/A2JQitsHzDwgcdBpUf7psX1BU=')
            data = Base64.strict_decode64(signature) + Base64.strict_decode64(classes_md5) + phone

            o = 0x5C.chr * 64
            i = 0x36.chr * 64
            64.times do | t |
              o[t] = (o[t].ord ^ key[t].ord).chr
              i[t] = (i[t].ord ^ key[t].ord).chr
            end

            output = Digest::SHA1.digest(o + Digest::SHA1.digest(i + data))

            Base64.strict_encode64(output)
          else
            md5 = "PdA2DJyKoUrwLw1Bg6EIhzh502dF9noR9uFCllGk#{RELEASE_TIME.to_s}#{phone}"
            Digest::MD5.hexdigest(md5)
        end
      end

      def Token.update_release_time(data)
        ver = data['e']
        if WHATSAPP_VER != ver
          #Update RELEASE TIME
          Dora::Protocol::Token.send(:remove_const, 'RELEASE_TIME') if Dora::Protocol::Token.const_defined?('RELEASE_TIME')
          Dora::Protocol::Token.const_set('RELEASE_TIME', data['e'])
        end
      end
    end
  end
end