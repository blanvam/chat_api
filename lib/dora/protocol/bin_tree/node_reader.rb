require 'dora/protocol/bin_tree/node'
require 'zlib'

require 'dora/protocol/bin_tree/reader/peek'
require 'dora/protocol/bin_tree/reader/read'

require 'dora/protocol/nodes/node'

module Dora
  module Protocol
    module BinTree
      class NodeReader < Node
        include BinTree::Reader::Peek
        include BinTree::Reader::Read

        def input
          @input
        end

        def input=input
          @input=input
        end

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
              @input = @key.decode_message(@input, real_size, 0, real_size)
              #if stanza_flag & 4
              #inflate_input
              #end
            end
          end
          if stanza_size > 0
            return next_tree_internal
          end
          nil
        end

        private

        def inflate_input
          @input = Zlib::Inflate.inflate(@input)
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
            return Nodes::Node.new(tag, attributes, nil, '')
          end
          token = read_int8
          if is_list_tag(token)
            return Nodes::Node.new(tag, attributes, read_list(token), '')
          end
          case token
            when 252
              len = read_int8
              data = fill_array len
              Nodes::Node.new(tag, attributes, nil, data)
            when 253
              len = read_int20
              data = fill_array len
              Nodes::Node.new(tag, attributes, nil, data)
            when 254
              len = read_int31
              data = fill_array len
              Nodes::Node.new(tag, attributes, nil, data)
            when 255, 251
              return Nodes::Node.new(tag, attributes, nil, read_packed8(token))
            else
              return Nodes::Node.new(tag, attributes, nil, read_string(token))
          end
        end

        def is_list_tag(token)
          token == 248 || token == 0 || token == 249
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
end