require 'chat_api/chat_api'

module Dora
  def Dora.data
    File.join File.dirname(__dir__), 'data'
  end
end