# encoding: utf-8
require 'chat_api/protocol/bin_tree_node'
require 'chat_api/protocol/token_map'

module Dora
	module Protocol
		class BinTreeNodeReader < BinTreeNode
			attr_accessor :input

			def next_tree(input = nil)
				@input = input unless input.nil?

				first_byte  = peek_int8
				stanza_size = peek_int16(1) | ((first_byte & 0x0F) << 16)
				stanza_flag = (first_byte & 0xF0) >> 4
				stanza_encrypted = ((stanza_flag & 8) != 0)

				raise ChatAPIError.new('Incomplete message stanza_size != ' + @input.length) if !@input.nil? && stanza_size > @input.length

				read_int24

				if stanza_encrypted
					if @key.nil?
						raise ChatAPIError('Encountered encrypted message, missing key')
					else
						#remaining_data = @input.byteslice(stanza_size..-1)
						#@input = @key.decode(@input.byteslice(0, stanza_size)) << remaining_data
						real_size = stanza_size - 4
						@input = @key.decode_message(@input, real_size, 0, real_size) # . $remainingData;
					end
				end
				if stanza_size > 0
					return next_tree_internal
				end
				nil
			end

			private

			def read_nibble
				byte = read_int8
				ignore_last_nibble = (byte & 0x80) > 0
				size = (byte & 0x7f)
				nr_of_nibbles = size * 2 - (ignore_last_nibble ? 1 : 0)

				data = fill_array(size)
				string = ''

				nr_of_nibbles.times do | i |
					byte = data[(i / 2).floor]
					ord = byte.ord

					shift = 4 * (1 - i % 2)
					decimal = (ord & (15 << shift)) >> shift

					case decimal
						when 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
							string += decimal.to_s
						when 10, 11
							string += (decimal - 10 + 45).chr
						else
							raise ChatAPIError.new('Bad nibble: $decimal')
					end
				end
				string
			end

			def get_token(token)
				ret, sub_dict = Dora::Protocol::TokenMap.get_token(token, false)
				if ret.nil?
					token = read_int8
					ret, sub_dict = Dora::Protocol::TokenMap.get_token(token, sub_dict)
					if ret.nil?
						raise ChatAPIError.new("BinTreeNodeReader get_token: Invalid token #{token}")
					end
				end
				ret
			end

			def read_string(token)
				if token > 2 && token < 0xf5
					get_token(token)
				elsif token == 0x00
					nil
				elsif token == 0xfc
					size = read_int8
					fill_array(size)
				elsif token == 0xfd
					size = read_int24
					fill_array(size)
				elsif token == 0xfa
					user   = read_string(read_int8)
					server = read_string(read_int8)
					if user.length > 0 && server.length > 0
						"#{user}@#{server}"
					elsif server.length > 0
						server
					else
						''
					end
				elsif token == 0xff
					read_nibble
				else
					''
				end
			end

			def read_attributes(size)
				attributes = {}
				attributes_count = (size - 2 + size % 2) / 2
				attributes_count.times do
					key = read_string(read_int8)
					value = read_string(read_int8)
					attributes[key] = value
				end
				attributes
			end

			def next_tree_internal
				token = read_int8
				size = read_list_size(token)
				token = read_int8
				if token == 1
					attributes = read_attributes(size)
					return ProtocolNode.new('start', attributes, nil, '')
				elsif token == 2
					return nil
				end
				tag = read_string(token)
				attributes = read_attributes(size)
				if (size % 2) == 1
					return ProtocolNode.new(tag, attributes, nil, '')
				end
				token = read_int8
				if is_list_tag(token)
					ProtocolNode.new(tag, attributes, read_list(token), '')
				else
					x = read_string(token)
					ProtocolNode.new(tag, attributes, nil, x)
				end
			end

			def is_list_tag(token)
				token == 248 || token == 0 || token == 249
			end

			def read_list(token)
				size = read_list_size(token)
				ret  = []
				size.times do ret.push(next_tree_internal) end
				ret
			end

			def read_list_size(token)
				if token == 0xf8
					return read_int8
				elsif token == 0xf9
					return read_int16
				end
				raise ChatAPIError.new("Read List Size: Invalid token #{token}")
			end

			def peek_int24(offset = 0)
				ret = 0
				if !@input.nil? && @input.length >= (3 + offset)
					#ret = (@input[offset, 1]).ord << 16
					#ret |= (@input[offset + 1, 1]).ord << 8
					#ret |= (@input[offset + 2, 1]).ord << 0
					ret = (@input.getbyte(offset) << 16) | (@input.getbyte(offset + 1) << 8) | (@input.getbyte(offset + 2))
				end
				ret
			end

			def read_int24
				ret = peek_int24
				#@input = @input[3, @input.length] if !@input.nil? && @input.length >= 3
				@input = @input.byteslice(3..-1) if !@input.nil? && @input.length >= 3
				ret
			end

			def peek_int16(offset = 0)
				ret = 0
				if !@input.nil? && @input.length >= (2 + offset)
					ret = (@input.getbyte(offset) << 8) | @input.getbyte(offset + 1)
					#ret = (@input[offset, 1]).ord << 8 | (@input[offset+1, 1]).ord << 0
				end
				ret
			end

			def read_int16
				ret = peek_int16
				if !@input.nil? && ret > 0
					@input = @input.byteslice(2..-1)
					#@input = @input[2, @input.length]
				end
				ret
			end

			def peek_int8(offset = 0)
				ret = 0
				if !@input.nil? && @input.length >= (1 + offset)
					ret = @input.getbyte(offset)
					#ret = (@input[offset, 1]).ord
				end
				ret
			end

			def read_int8
				ret = peek_int8
				if !@input.nil? && @input.length >= 1
					@input = @input.byteslice(1..-1)
					#@input = @input[1, @input.length]
				end
				ret
			end


			def fill_array(length)
				return ''.force_encoding(BINARY_ENCODING) if @input.bytesize < length

				result = @input.byteslice(0, length)
				@input = @input.byteslice(length..-1)
				if result.force_encoding(UTF8_ENCODING).valid_encoding?
					result.encode!(UTF8_ENCODING)
				else
					result.force_encoding(BINARY_ENCODING)
				end
			end
		end
	end
end