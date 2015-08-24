module Dora

  # CUSTOM ERROR CLASSES

  # All of our custom errors are superclassed by JabberError < StandardError
  class ChatAPIError < StandardError; end

  # A client-side only argument error
  class ArgumentError < ChatAPIError; end

  # A client-authentication failure
  class ClientAuthenticationFailure < ChatAPIError; end

  # Server connection error
  class ConnectionFailure < RuntimeError; end

  # Server timeout error
  class SocketTimeout < SocketError; end

  # Server disconnected us
  class ServerDisconnected < ChatAPIError; end

end
