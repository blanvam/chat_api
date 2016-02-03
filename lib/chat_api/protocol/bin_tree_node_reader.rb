# encoding: utf-8
require 'chat_api/protocol/bin_tree_node'
require 'chat_api/protocol/token_map'
require 'zlib'

module Dora
	module Protocol
		class BinTreeNodeReader < BinTreeNode
			attr_accessor :input

			def next_tree(input = nil)
        @input = input unless input.nil?

				first_byte  = peek_int8
				stanza_flag = (first_byte & 0xF0) >> 4
				stanza_size = peek_int16(1) | ((first_byte & 0x0F) << 16)

				raise ChatAPIError.new('Incomplete message stanza_size != ' + @input.length) if !@input.nil? && stanza_size > @input.length

				read_int24

				if (stanza_flag & 8) != 0
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

      def get_token_double(n1, n2)
        pos = n2 + n1 * 256
        ret, sub_dict = Dora::Protocol::TokenMap.get_token(pos, true)
        raise ChatAPIError.new("BinTreeNodeReader->getToken: Invalid token #{pos}(#{n2} + #{n1} * 256)") unless ret
        ret
      end

			def read_string(token)
        raise ChatAPIError.new('BinTreeNodeReader->readString: Invalid token $token') if token == -1
				if token > 2 && token < 236
					get_token(token)
        else
          case token
            when 0
              ''
            when 236, 237, 238, 239
              token2 = read_int8
              get_token_double(token-236, token2)
            when 250
              user   = read_string(read_int8)
              server = read_string(read_int8)
              if !user.nil? && !server.nil?
                "#{user}@#{server}"
              elsif server.nil?
                ''
              end
            when 251, 252
              size = read_int8
              fill_array(size)
            when 253
              size = read_int20
              fill_array(size)
            when 254
              size = read_int31
              fill_array(size)
            when 255
              read_packed8(token)
            else
              raise ChatAPIError.new("readString couldn't match token #{token}")
          end
        end
      end

      def read_packed8(n)
        len = read_int8
        remove = ((len & 0x80) != 0 && n == 251) ? 1 : 0
        len = len & 0x7F
        text = @input.byteslice(0, len)
        @input = @input.byteslice(len..-1)
        data = text.unpack('H*')[0]
        len = data.length
        out = ''
        len.times do | i |
          val = (hex2bin('0'+data[i])).ord
          break if i == (len-1) && val > 11 && n != 251
          out += unpack_byte(n, val).chr
        end
        out.byteslice(0,(out.length-remove))
      end

      def unpack_byte(n1, n2)
        case n1
          when 251
            unpack_hex n2
          when 255
            unpack_nibble(n2)
          else
            raise ChatAPIError.new("Bad packed type #{n1}")
        end
      end

      def unpack_hex(n)
        case n
          when 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
            n + 48
          when 10, 11, 12, 13, 14, 15
            65 + (n - 10)
          else
            raise ChatAPIError.new("Bad hex #{n}")
        end
      end

      def unpack_nibble(n)
        case n
          when 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
            n + 48
          when 10, 11
            45 + (n - 10)
          else
            raise ChatAPIError.new("Bad nibble #{n}")
        end
      end

      def read_attributes(size)
				attributes = {}
				attributes_count = (size - 2 + size % 2) / 2
				attributes_count.times do
          len1 = read_int8
					key = read_string(len1)
          len2 = read_int8
					value = read_string(len2)
					attributes[key] = value
				end
				attributes
			end

      def inflate_buffer(stanza_size = 0)
        gz = Zlib::GzipReader.new(@input)
        @input = gz.read
      end

			def next_tree_internal
        size = read_list_size(read_int8)
        raise ChatAPIError.new('next_tree sees 0 list or null tag') if size == 0 || size.nil?

        token = read_int8
				token = read_int8 if token == 1
        return nil if token == 2

				tag = read_string(token)
				attributes = read_attributes(size)
				if (size % 2) == 1
					return ProtocolNode.new(tag, attributes, nil, '')
				end
				token = read_int8
				if is_list_tag(token)
					return ProtocolNode.new(tag, attributes, read_list(token), '')
        end
        case token
          when 252
            len = read_int8
            data = fill_array len
            ProtocolNode.new(tag, attributes, nil, data)
          when 253
            len = read_int20
            data = fill_array len
            ProtocolNode.new(tag, attributes, nil, data)
          when 254
            len = read_int31
            data = fill_array len
            ProtocolNode.new(tag, attributes, nil, data)
          when 255, 251
            return ProtocolNode.new(tag, attributes, nil, read_packed8(token))
          else
            return ProtocolNode.new(tag, attributes, nil, read_string(token))
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
        return 0 if token == 0
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
          ret = (@input.byteslice(offset).ord << 16) | (@input.byteslice(offset + 1).ord << 8) | @input.byteslice(offset + 2).ord
				end
				ret
			end

      def read_header(offset = 0)
        ret = 0
        if @input.length >= (3 + offset)
          ret = @input.byteslice(offset).ord + ( (@input.byteslice(offset + 1).ord << 16) + (@input.byteslice(offset + 2).ord << 8) )
        end
        ret
      end

			def read_int24
				ret = peek_int24
				@input = @input.byteslice(3..-1) if !@input.nil? && @input.length >= 3
				ret
			end

			def peek_int16(offset = 0)
				ret = 0
				if !@input.nil? && @input.length >= (2 + offset)
					ret = (@input.byteslice(offset).ord << 8) | @input.byteslice(offset + 1).ord
				end
				ret
			end

			def read_int16
				ret = peek_int16
				if !@input.nil? && ret > 0
					@input = @input.byteslice(2..-1)
				end
				ret
			end

			def peek_int8(offset = 0)
				ret = 0
				if !@input.nil? && @input.length >= (1 + offset)
					ret = @input.byteslice(offset).ord
				end
				ret
			end

			def read_int8
				ret = peek_int8
				if !@input.nil? && @input.length >= 1
					@input = @input.byteslice(1..-1)
				end
				ret
			end

      def peek_int20(offset = 0)
        ret = 0
        if @input.length >= (3 + offset)
          b1 = @input.byteslice(offset).ord
          b2 = @input.byteslice(offset + 1).ord
          b3 = @input.byteslice(offset + 2).ord
          ret = (b1 << 16) | (b2 << 8) | b3
        end
        ret
      end

      def read_int20
        ret = peek_int20
        if !@input.nil? && @input.length >= 3
          @input = @input.byteslice(3..-1)
        end
        ret
      end

      def peek_int31(offset = 0)
        ret = 0
        if @input.length >= (4 + offset)
          b1 = @input.byteslice(offset).ord
          b2 = @input.byteslice(offset + 1).ord
          b3 = @input.byteslice(offset + 2).ord
          b4 = @input.byteslice(offset + 3).ord
            # n = 0x7F & b1
          ret = (b1 << 24) | (b2 << 16) | (b3 << 8) | b4
        end
        ret
      end

      def read_int31
        ret = peek_int31
        if !@input.nil? && @input.length >= 4
          @input = @input.byteslice(4..-1)
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