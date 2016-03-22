# encoding: utf-8

require 'openssl'
require 'base64'

require 'dora/protocol/rc4'

module Dora
	module Protocol
		class KeyStream
			AUTH_METHOD = 'WAUTH-2'
			DROP = 768
			BINARY_ENCODING = Encoding.find('binary') #Encoding::ASCII_8BIT
			UTF8_ENCODING   = Encoding.find('UTF-8')

			def initialize(key, mac_key)
				@rc4 = Rc4.new(key, DROP)
				@mac_key = mac_key
				@seq = 0
			end

			def self.generate_keys(password, challenge)
				array = %w(key key key key)
				challenge << '0'
				0.upto(3) do |idx|
					challenge[challenge.length-1] = (idx+1).chr
					foo = OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, challenge, 2, 20)
					array[idx] = foo
				end
				array
			end

			def decode_message(buffer, mac_offset, offset, length)
				mac = compute_mac(buffer, offset, length)
				4.times do |i|
					foo = (buffer[mac_offset + i]).ord
					bar = mac[i].ord
					if foo != bar
						fail ChatAPIError.new("MAC mismatch: #{foo != bar}")
					end
				end
				@rc4.cipher(buffer, offset, length)
			end

			def encode_message(buffer, mac_offset, offset, length)
				data = @rc4.cipher(buffer, offset, length)
				mac = compute_mac(data, offset, length)
				"#{data[0, mac_offset]}#{mac[0, 4]}#{data[mac_offset + 4, data.length]}"
			end

			private

			def compute_mac(buffer, offset, length)
				array = (@seq >> 24).chr + (@seq >> 16).chr + (@seq >> 8).chr + (@seq).chr
				data = "#{buffer[offset, length]}#{array}"
				@seq += 1
				OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), @mac_key, data)
			end

		end
	end
end