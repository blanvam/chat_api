# encoding: utf-8
module Dora
	module Protocol
		class Rc4
			BINARY_ENCODING = Encoding.find('binary')

			def initialize(key, drop)
				begin
					raise SyntaxError, 'RC4: Key supplied is blank' if key.eql?('')
					initialize_state(key)
					@q1, @q2 = 0, 0
				end
				cipher((0..drop).to_a, 0, drop)
			end

			def cipher(data, offset, length)
				out = data
				n = length
				while n > 0  do
					@q1 = (@q1 + 1) & 0xff #% 256
					@q2 = (@q2 + @state[@q1]) & 0xff
					@state[@q1], @state[@q2] = @state[@q2], @state[@q1]

					d = (data[offset]).to_s.ord
					out[offset] = (d ^ @state[(@state[@q1] + @state[@q2]) & 0xff]).chr
					offset += 1
					n -= 1
				end
				out
			end

			private

			# The initial state which is then modified by the key-scheduling algorithm
			INITIAL_STATE = (0..255).to_a

			# Performs the key-scheduling algorithm to initialize the state.
			def initialize_state(key)
				i = j = 0
				@state = INITIAL_STATE.dup
				key_length = key.length
				while i < 256
					k = key.getbyte(i % key_length)
					j = (j + k + @state[i] ) % 256
					@state[i], @state[j] = @state[j], @state[i]
					i += 1
				end
			end
		end
	end
end
