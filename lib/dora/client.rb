require 'dora/logger'
require 'dora/util'
require 'dora/registration'

require 'dora/process_node'

require 'dora/errors'
require 'dora/util'

require 'dora/protocol'
require 'dora/protocol/process/stanzas'

module Dora
  include Logging
  include Util
  include Protocol
  include Stanzas

  class Client
    include Registration

    attr_reader :auth, :jid

    private :auth

    def initialize(number, name = '', options = {})
      logger.enable_debug if options[:debug]
      @jid = JID.new(number, name)
      @node_id = {}
      @auth = Authentication.new number
      @conn = Connection.new
      @conn.connect
    end

    def request_last_seen(to)
      msg_id = @node_id['getlastseen'] = create_iq_id
      send_get_last_seen(id, to.to_jid.to_s)
      wait_for_server(msg_id)
    end

    def presence_subscription(to)
      send_node(PresenceNode.new({type: 'subscribe', to: to.to_jid.to_s}))
    end

    def synchronize(numbers, deleted_numbers = nil, sync_type = 4, index = 0, last = true)
      child = SyncNode.new(numbers, deleted_numbers, sync_type, index, last)
      id = create_iq_id
      puts "synchronize: #{id}"
      node = IqNode.new(id, nil, 'get', 'urn:xmpp:whatsapp:sync', [child])
      send_node node
      wait_for_server(id)
      id
    end

    def login(password)
      do_login(password)
      @reg = nil
    end

    def do_login(password)
      return true if @conn.logged?

      @conn.send_pre_login FeatureNode.new
      input, output = @auth.authentication(password)
      @conn.update_reader(input) if input
      send_node AuthNode.new(@auth.id, output)

      3.times do
        get_and_process_next_node
      end

      unless @auth.data.nil?
        send_node AuthResponseNode.new(@auth.authenticate(password))
        @conn.update_reader @auth.key_input
        @conn.update_writer @auth.key_output
        until get_and_process_next_node do 1 end
      end

      raise ChatAPIError.new('Login failure') unless @conn.logged?

      available_for_chat
      privacy_blocked_list
      send_get_client_config(create_iq_id)
      message_id = Digest::SHA1.hexdigest("--#{rand(10000)}--#{Time.now}--")[0,12]

      #Base64.strict_decode64(password)

      true
    end

    def get_and_process_next_node
      begin
        node = @conn.poll_message
      rescue ConnectionTimeout
        send_ping
      end
      process_node(node)
      node
    end

    def send_node(node)
      @conn.send_node(node)
    end

    private

    def wait_for_server(id, timeout = 5)
      server_received_id = ''
      time = Time.now
      begin
        node = get_and_process_next_node
        server_received_id = node.attributes['id'] unless node.nil?
      end while server_received_id != id && Time.now - time < timeout
    end

    def available_for_chat(name = nil)
      @jid.name = name if name
      send_presence({name: @jid.name})
    end

    def privacy_blocked_list
      id = @node_id['privacy'] = create_iq_id
      send_get_privacy_blocked_list(id)
    end

    end
end