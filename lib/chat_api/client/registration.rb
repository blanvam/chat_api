require 'rest-client'
require 'active_support'
require 'active_support/core_ext/object/to_query'

require 'chat_api/client/identity'
require 'chat_api/client/token'
require 'chat_api/client/utils'

module Dora
  class Client
    class Registration
      include ActiveSupport::JSON
      include Utils

      def initialize(number, identity_file_path = nil)
        @number = number
        @identity = Identity.new(number, identity_file_path)
      end

      def get_code(method = 'sms', carrier = '', platform = 'Android')
        phone = dissect_phone(@number)
        raise ArgumentError.new('The provided phone number is not valid.') unless phone

        country_code = (phone[:ISO3166] != '') ? phone[:ISO3166] : 'US'
        lang_code    = (phone[:ISO639] != '') ? phone[:ISO639] : 'en'

        mnc = carrier.nil? ? phone[:mnc] : detect_mnc(country_code.downcase, carrier)

        # Build the token.
        token = Token::generate_request_token(phone[:phone], platform)

        # Build the url.
        host = 'https://' + WHATSAPP_REQUEST_HOST
        query = {
            cc: phone[:cc],
            in: phone[:phone],
            lg: lang_code,
            lc: country_code,
            id: @identity.to_s,
            token: token,
            mistyped: '6',
            network_radio_type: '1',
            simnum: '1',
            s: '',
            copiedrc: '1',
            hasinrc: '1',
            rcmatch: '1',
            pid: rand(9899)+100,
            rchash: Digest::SHA256.hexdigest(Random.new.bytes(20)),
            anhash: Digest::MD5.hexdigest(Random.new.bytes(20)),
            extexist: '1',
            extstate: '1',
            mcc: phone[:mcc],
            mnc: mnc,
            sim_mcc: phone[:mcc],
            sim_mnc: mnc,
            method: method
        }

        response = get_response(host, query)

        if response['status'] == 'sent'
          response
        elsif response['status'] != 'sent'
          if response['reason'].present? && !response['reason'].nil? && response['reason'] == 'too_recent'
            minutes = (response['retry_after'] / 60).round(2)
            message = "Code already sent. Retry after #{minutes} minutes."
          elsif response['reason'].present? && !response['reason'].nil?  && response['reason'] == 'too_many_guesses'
            message = 'Too many guesses.'
          elsif response['reason'].present? && !response['reason'].nil?  && response['reason'] == 'blocked'
            message = 'The number is blocked.'
          else
            message = 'There was a problem trying to request the code.'
          end
          raise RegistrationError.new(message, response)
        else
          raise RegistrationError.new('Failed.', response)
        end
      end

      def send_code(code)
        phone = dissect_phone(@number)
        raise ArgumentError.new('The provided phone number is not valid.') unless phone

        # Build the url.
        host = 'https://' + WHATSAPP_REGISTER_HOST
        query = {
            cc: phone[:cc],
            in: phone[:phone],
            id: @identity.to_s,
            code: code
        }
        response = get_response(host, query)

        if response['status'] != 'ok'
          if response['reason'] == 'old_version'
            update_version
          end
          raise RegistrationError.new('An error occurred registering the registration code from WhatsApp. Reason: ' + response['reason'], response)
        end
        response
      end

      def check_credentials
        phone = dissect_phone(@number)
        raise ArgumentError.new('The provided phone number is not valid.') unless phone

        country_code = (phone[:ISO3166] != '') ? phone[:ISO3166] : 'US'
        lang_code    = (phone[:ISO639] != '') ? phone[:ISO639] : 'en'

        if phone[:cc] == '77' || phone[:cc] == '79'
          phone[:cc] = '7'
        end

        # Build the url.
        host = 'https://' + WHATSAPP_CHECK_HOST
        query = {
            cc: phone[:cc],
            in: phone[:phone],
            id: @identity.to_s,
            lg: lang_code,
            lc: country_code,
            mistyped: '6',
            network_radio_type: '1',
            simnum: '1',
            s: '',
            copiedrc: '1',
            hasinrc: '1',
            rcmatch: '1',
            pid: rand(100..9999),
            extexist: '1',
            extstate: '1',
        }
        response = get_response(host, query)

        if response['status'] != 'ok'
          case response['reason']
            when 'incorrect'
              message = 'You have wrong identity. Register number again or copy identity to a file in wadata folder.'
            when 'blocked'
              message = 'Your number is blocked.'
            else
              message = 'There was a problem trying to request the code.'
          end
          raise RegistrationError.new(message, response)
        end
        response
      end

      private

      def get_response(host, query)
        url = "#{host}?#{query.to_query}"

        resource = RestClient::Resource.new(
            url,
            :user_agent => WHATSAPP_USER_AGENT,
            :verify_ssl => 0, #OpenSSL::SSL::VERIFY_NONE,
            :accept     => 'text/json'
        )

        response = resource.get :user_agent => WHATSAPP_USER_AGENT,
                                :accept => 'text/json'

        ActiveSupport::JSON.decode(response)
      end
    end
  end
end