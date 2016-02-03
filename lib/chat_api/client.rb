require 'chat_api/connector'
require 'chat_api/client/registration'
require 'chat_api/logger'

module Dora
  include Logging

  class Client
    attr_reader :jid

    def initialize(number, name = '', debug = false, identity_file = nil)
      logger.enable_debug if debug
      @jid = Dora::Protocol::JID.new(number, name)
      @con = Dora::Connector.new(number)
      @con.connect
    end

    # Registers methods
    def code_request(method = 'sms', carrier = nil)
      set_reg
      @reg.get_code(method, carrier)
    end

    def code_register(code)
      set_reg
      @reg.send_code(code)
    end

    def check_credentials
      set_reg
      @reg.check_credentials
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
      @con.profile_image @jid.to_s, path
    end

    def server_properties
      @con.server_properties
    end

    def client_configuration
      @con.client_configuration
    end

    def synchronize(sync)
      @con.synchronize sync
    end

    def poll
      @con.poll_message
    end

    def presence_subscription(target)
      @con.presence_subscription target
    end

    def send_message(to,message)
      @con.send_message to, message
    end

    def send_image(to, file_path, store_url_media = false, f_size = 0, f_hash = '', caption = '')
      @con.send_image to, file_path, store_url_media, f_size, f_hash, caption
    end

    def messages
      @con.get_messages
    end

    private

    def set_reg
      @reg ||= Dora::Client::Registration.new(@jid.number)
    end
  end
end