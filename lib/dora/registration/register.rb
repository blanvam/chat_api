require 'dora/registration/identity'
require 'dora/registration/phone'
require 'dora/registration/token'
require 'dora/registration/utils'
require 'dora/util'

module Dora
  module Registration
    # The Registration class has all methods needed to register a whatsapp number.
    class Register
      include Util
      include Utils

      def initialize(number, identity_file_path = nil)
        @phone = Phone.new(number)
        @identity = Identity.new(number, identity_file_path)
      end

      def phone
        @phone
      end

      def get_code(method = 'sms', carrier = '', platform = 'Android')
        host = 'https://' + WHATSAPP_REQUEST_HOST
        query = get_code_hash(method, carrier, platform)

        response = get_rest_service(host, query)

        default_message = 'There was a problem trying to request the code.'
        process_response(response, default_message)
      end

      def send_code(code)
        host = 'https://' + WHATSAPP_REGISTER_HOST
        query = send_code_hash(code)

        response = get_rest_service(host, query)

        default_message = "An error occurred registering the registration code from WhatsApp. Reason: #{response['reason']}"
        process_response(response, default_message)
      end

      def check_credentials
        host = 'https://' + WHATSAPP_CHECK_HOST
        query = check_credentials_hash

        response = get_rest_service(host, query)

        default_message = 'There was a problem trying to request the code.'
        process_response(response, default_message)
      end

      private

      def get_code_hash(method, carrier, platform)
        number = phone.number
        token = Token.new(number)
        tok = token.generate(platform)
        mnc = phone.mnc(carrier)
        mcc = phone.mcc
        rc_hash = Digest::SHA256.hexdigest(random_bytes(20))
        an_hash = Digest::MD5.hexdigest(random_bytes(20))

        {
            cc: phone.cc, in: number, lg: phone.lang_code, lc: phone.country_code, id: @identity.to_s, token: tok,
            mistyped: '6', network_radio_type: '1', simnum: '1', s: '', copiedrc: '1', hasinrc: '1', rcmatch: '1',
            pid: rand(9899)+100, rchash: rc_hash, anhash: an_hash, extexist: '1', extstate: '1', mcc: mcc, mnc: mnc,
            sim_mcc: mcc, sim_mnc: mnc, method: method
        }
      end

      def send_code_hash(code)
        { cc: phone.cc, in: phone.number, id: @identity.to_s, code: code }
      end

      def check_credentials_hash
        {
            cc: phone.cc, in: phone.number, id: @identity.to_s, lg: phone.lang_code, lc: phone.country_code,
            mistyped: '6', network_radio_type: '1', simnum: '1', s: '', copiedrc: '1', hasinrc: '1',
            rcmatch: '1', pid: rand(100..9999), extexist: '1', extstate: '1',
        }
      end

    end
  end
end