require 'chat_api/connector'

require 'chat_api/protocol/identity'
require 'chat_api/protocol/token'
require 'chat_api/protocol/utils'

module Dora

  class Client < Connector
    include Dora::Protocol::Utils

    attr_reader :jid

    def initialize(number, name = '', identity_file = nil, debug = false)
      @jid = Dora::Protocol::JID.new(number, name)
      @identity = Dora::Protocol::Identity.new(number, identity_file)
      super(number)
    end

    def code_request(method = 'sms', carrier = nil)
      phone = dissect_phone(@jid.number)
      raise ArgumentError.new('The provided phone number is not valid.') unless phone

      country_code = (phone[:ISO3166] != '') ? phone[:ISO3166] : 'US'
      lang_code    = (phone[:ISO639] != '') ? phone[:ISO639] : 'en'

      if carrier.nil?
        mnc = phone[:mnc]
      else
        mnc = detect_mnc(country_code.downcase, carrier)
      end

      # Build the token.
      token = Dora::Protocol::Token::generate_request_token(phone[:phone])

      # Build the url.
      host = 'https://' + WHATSAPP_REQUEST_HOST
      query = {
          in: phone[:phone],
          cc: phone[:cc],
          id: @identity.to_s,
          lg: lang_code,
          lc: country_code,
          sim_mcc: phone[:mcc],
          sim_mnc: mnc,
          method: method,
          token: token,
      }

      response = get_response(host, query)

      if response['status'] == 'sent'
        response
      elsif response['status'] != 'sent'
        if response['reason'].present? && !response['reason'].nil? && response['reason'] == 'too_recent'
          minutes = (response['retry_after'] / 60).round(2)
          raise ChatAPIError.new("Code already sent. Retry after #{minutes} minutes.")
        elsif response['reason'].present? && !response['reason'].nil?  && response['reason'] == 'too_many_guesses'
          minutes = (response['retry_after'] / 60).round(2)
          raise ChatAPIError.new("Too many guesses. Retry after #{minutes} minutes.")
        else
          raise ChatAPIError.new('There was a problem trying to request the code.')
        end
      else
        raise ChatAPIError.new('Failed.')
      end
    end

    def code_register(code)
      phone = dissect_phone(@jid.number)
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
        raise ChatAPIError.new('An error occurred registering the registration code from WhatsApp. Reason: ' + response['reason'])
      end
      response
    end

    def check_credentials(code = nil)
      phone = dissect_phone(@jid.number)
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
          lc: country_code
      }
      query[:code] = code unless code.nil?

      response = get_response(host, query)

      if response['status'] != 'ok'
        message = response['reason'] == 'incorrect' ?
            'You have wrong identity. Register number again or copy identity to a file in wadata folder'
        :
            'There was a problem trying to request the code.'

        raise ChatAPIError.new(message)
      end
      response
    end

    def login(password)
      @password = password
      do_login(password)
      send_available_for_chat
    end

    def send_available_for_chat(name = nil)
      @jid.name= name if name
      send_presence({name: @jid.name})
    end

    def set_profile_picture(path)
      profile_image(@jid.to_s, path)
    end

    def set_new_message_bind(bind) #1974
      @message_bind = bind
    end

    private

  end
end