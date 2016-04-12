module Dora
  # Various utility functions
  module Util
    # Hex encodes a message
    #
    # @param [String] bytes The bytes to encode
    #
    # @return [String] Tasty, tasty hexadecimal
    def bin2hex(bytes)
      bytes.to_s.unpack('H*').first
    end

    # Hex decodes a message
    #
    # @param [String] hex hex to decode.
    #
    # @return [String] crisp and clean bytes
    def hex2bin(hex)
      [hex.to_s].pack('H*')
    end

    # Generate random string of bytes
    #
    # @param [Integer] size of the string
    #
    # @return [String] of size bytes
    def random_bytes(size)
      SecureRandom.random_bytes(size)
    end

    # Generate random string of hexadecimals
    #
    # @param [Integer] size of the string
    #
    # @return [String] of size hexadecimals
    def random_hex(size)
      SecureRandom.hex(size)
    end
  end
end
