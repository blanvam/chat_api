module Dora
  module Protocol
    class Authentication < Challenge

      def initialize(number)
        @keys = { input: nil, output: nil}
        super
      end

      def key_input
        @keys[:input]
      end

      def key_output
        @keys[:output]
      end

      def authentication(password)
        unless @data.nil?
          key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(Base64.strict_decode64(password), @data, 16, 20)
          @keys[:input] = KeyStream.new(key[2], key[3])
          @keys[:output] = KeyStream.new(key[0], key[1])
          array = "\0\0\0\0#{id}#{@data}1453420825" #{Time.now.getutc.to_i.to_s}"
          @data = nil
          return [@keys[:input],@keys[:output].encode_message(array, 0, array.length, 0)]
        end
        [nil, nil]
      end

      def authenticate(password)
        keys = KeyStream.generate_keys(Base64.strict_decode64(password), @data.clone)
        @keys[:input] = KeyStream.new(keys[2], keys[3])
        @keys[:output] = KeyStream.new(keys[0], keys[1])
        array = "\0\0\0\0#{id.force_encoding(BINARY_ENCODING)}#{@data}#{Time.now.getutc.to_i.to_s}" + '000' +
            hex2bin('00') + '000' + hex2bin('00') + OS_VERSION + hex2bin('00') + MANUFACTURER + hex2bin('00') + DEVICE + hex2bin('00') + BUILD_VERSION
        @keys[:output].encode_message(array, 0, 4, (array.length - 4))
      end

    end
  end
end