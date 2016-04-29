require 'dora/protocol/nodes'
require 'dora/protocol/process'

module Dora
  module Protocol
    autoload :JID,          'dora/protocol/jid'
    autoload :Connection,   'dora/protocol/connection'

    module Auth
      autoload :Authentication,   'dora/protocol/auth/authentication'
    end

    include Nodes
    include Process
    include Auth
  end
end