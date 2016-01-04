require 'chat_api/connector'
require 'chat_api/client/registration'

module Dora
  class Client

    attr_reader :jid

    def initialize(number, name = '', debug = false, identity_file = nil)
      @jid = Dora::Protocol::JID.new(number, name)
      @con = Dora::Connector.new(number)
    end

    # Registers methods
    def code_request(method = 'sms', carrier = nil)
      @reg ||= Dora::Client::Registration.new(@jid.number)
      @reg.get_code(method, carrier)
    end

    def code_register(code)
      @reg ||= Dora::Client::Registration.new(@jid.number)
      @reg.send_code(code)
    end

    def check_credentials(code = nil)
      @reg ||= Dora::Client::Registration.new(@jid.number)
      @reg.check_credentials(code)
    end

    # Flow
    def login(password)
      @pwd = password
      @con.do_login(password)
      @reg = nil if @reg
      send_available_for_chat
    end

    def send_available_for_chat(name = nil)
      @jid.name = name if name
      @con.send_presence({name: @jid.name})
    end

    def set_profile_picture(path)
      @con.profile_image(@jid.to_s, path)
    end

  end
end