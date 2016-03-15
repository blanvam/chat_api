require 'dora/logger'
require 'dora/client_registration'
require 'dora/connector'

module Dora
  include Logging

  # Client class to connect with WhatsApp
  class Client
    include ClientRegistration

    attr_reader :jid

    def initialize(number, name = '', options = {})
      logger.enable_debug if options[:debug]
      @jid = Dora::Protocol::JID.new(number, name)
      @con = Dora::Connector.new(number)
      @con.connect
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

    def send_image(to, file_path, *args)
      @con.send_image to, file_path, args
    end

    def messages
      @con.get_messages
    end

  end
end