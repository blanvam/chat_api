require 'dora/protocol/bin_tree/token_map'

module Dora
  module Protocol
    module BinTree
      module Reader
        module Read

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
                  raise ChatAPIError.new("BinTree::NodeReader.read_nibble: Bad nibble #{decimal}")
              end
            end
            string
          end

          def read_string(token)
            raise ChatAPIError.new("BinTree::NodeReader.read_string: Invalid -1 token #{token}") if token == -1
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
                  raise ChatAPIError.new("BinTree::NodeReader.read_string: Couldn't match token #{token}")
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
            raise ChatAPIError.new("BinTree::NodeReader.read_list_size: invalid list size token #{token}")
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

          def read_int16
            ret = peek_int16
            if !@input.nil? && ret > 0
              @input = @input.byteslice(2..-1)
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

          def read_int20
            ret = peek_int20
            if !@input.nil? && @input.length >= 3
              @input = @input.byteslice(3..-1)
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

          def get_token(token)
            ret, primary = Dora::Protocol::BinTree::TokenMap.parse(token)
            if ret.nil?
              token = read_int8
              ret = Dora::Protocol::BinTree::TokenMap.parse(token, primary)[0]
              if ret.nil?
                raise ChatAPIError.new("BinTree::NodeReader.get_token: Invalid token / length #{token}")
              end
            end
            ret
          end

          def get_token_double(n1, n2)
            pos = n2 + n1 * 256
            ret = Dora::Protocol::BinTree::TokenMap.parse_secondary(pos)
            raise ChatAPIError.new("BinTree::NodeReader.get_token_double: Invalid token #{pos}(#{n2} + #{n1} * 256)") unless ret
            ret
          end

          def unpack_byte(n1, n2)
            case n1
              when 251
                unpack_hex n2
              when 255
                unpack_nibble(n2)
              else
                raise ChatAPIError.new("BinTree::NodeReader.unpack_byte: Bad packed type #{n1}")
            end
          end

          def unpack_hex(n)
            case n
              when 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                n + 48
              when 10, 11, 12, 13, 14, 15
                65 + (n - 10)
              else
                raise ChatAPIError.new("BinTree::NodeReader.unpack_hex: Bad hex #{n}")
            end
          end

          def unpack_nibble(n)
            case n
              when 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                n + 48
              when 10, 11
                45 + (n - 10)
              else
                raise ChatAPIError.new("BinTree::NodeReader.unpack_nibble: Bad nibble #{n}")
            end
          end

        end
      end
    end
  end
end