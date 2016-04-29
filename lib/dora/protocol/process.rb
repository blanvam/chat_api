require 'dora/protocol/process/identifiers'
require 'dora/protocol/process/sender'

module Dora
  module Protocol
    module Process
      include Identifiers
      include Sender
    end
  end
end