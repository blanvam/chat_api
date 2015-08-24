require 'chat_api/protocol/nodes/protocol_node'

module Dora
  module Protocol
    class IqNode < ProtocolNode

      def initialize(id, to, type, xmlns = nil, children = nil, data = nil)
        to = WHATSAPP_SERVER if to.nil?
        attributes = {id: id, type: type, to: to}
        attributes[:xmlns] = xmlns unless xmlns.nil?

        super('iq', attributes, children, data)
      end
    end
  end
end