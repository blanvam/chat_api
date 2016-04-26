module Dora

  # CUSTOM ERROR CLASSES

  # All of our custom errors are superclassed by ChatAPIError < StandardError
  class ChatAPIError < StandardError; end

  class ConnectionTimeout < RuntimeError; end

  class TokenError < ChatAPIError; end

  # A client-side only argument error
  class ArgumentError < ChatAPIError; end

  # A client-registration error
  class RegistrationError < ChatAPIError
    attr_reader :object
    def initialize(message, object)
      super(message)
      @object = object
    end

    def to_s
      'Registration error: ' + super
    end
  end

  # A client-authentication failure
  class ClientAuthenticationFailure < ChatAPIError; end

  # Server connection error
  class ConnectionFailure < RuntimeError; end

  # Server timeout error
  class SocketTimeout < SocketError; end

  # Server disconnected
  class ServerDisconnected < ChatAPIError; end

  # Empty header
  class HeadEmpty < ChatAPIError; end
end
