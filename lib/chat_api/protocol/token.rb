# encoding: utf-8
require 'digest/md5'

module Dora
  module Protocol
    class Token
      RELEASE_TIME = '1439921717185'

      def Token.generate_request_token(phone)
        md5 = "PdA2DJyKoUrwLw1Bg6EIhzh502dF9noR9uFCllGk#{RELEASE_TIME.to_s}#{phone}"
        Digest::MD5.hexdigest(md5)
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