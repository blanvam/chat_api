require 'dora/protocol/bin_tree/node'
require 'dora/protocol/token_map'

require 'dora/protocol/bin_tree/writer/helper'

module Dora
  module Protocol
    module BinTree
      module Writer
        class BaseWriter < Node

          include Helper

          attr_reader :output

          def initialize
            @output = ''
          end

          private

          def flush_buffer(encrypt=true)
            size = @output.size
            data = @output.clone
            if !@key.nil? && encrypt
              b_size = get_int24(size)
              # encrypt
              data = @key.encode_message(data, size, 0, size)
              len = data.size
              b_size[0] = ((8 << 4) | ((len & 16711680) >> 16)).chr
              b_size[1] = ((len & 65280) >> 8).chr
              b_size[2] = (len & 255).chr
              size = parse_int24(b_size)
            end
            result = ((size & 0xff0000) >> 16).chr << ((size & 0x00ff00) >> 8).chr << ((size & 0x0000ff) >> 0).chr << data
            @output.clear
            result
          end

          def write_int8(int)
            @output << (int & 0xff).chr
          end

          def write_int16(int)
            @output << ((int & 0xff00) >> 8).chr << ((int & 0x00ff) >> 0).chr
          end

          def write_int20(int)
            @output << ((0xF0000 & int) >> 16).chr << ((0xFF00 & int) >> 8).chr << ((int & 0xFF) >> 0).chr
          end

          def write_int24(int)
            @output << ((int & 0xff0000) >> 16).chr << ((int & 0x00ff00) >> 8).chr << ((int & 0x0000ff) >> 0).chr
          end

          def write_int31(int)
            @output << ((0x7F000000 & int) >> 24).chr << ((0xFF0000 & int) >> 16).chr << ((0xFF00 & int) >> 8).chr << ((int & 0xFF) >> 0).chr
          end

          def get_int24(size)
            ((size & 0xf0000) >> 16).chr << ((size & 0xff00) >> 8).chr << (size & 0xff).chr
          end

          def parse_int24(b_size)
            b_size.byteslice(0, 1).ord << 16  | b_size.byteslice(1, 1).ord << 8 | b_size.byteslice(2, 1).ord << 0
          end

          def write_bytes(bytes, b = false)
            len = bytes.size
            to_write = bytes
            if len >= 0x100000
              write_int8(0xfe)
              write_int31(len)
            else
              if len >= 0x100
                write_int8(0xfd)
                write_int20(len)
              else
                r = ''
                if b
                  if len < 128
                    r = try_pack_and_write_header(255, bytes)
                    if r == ''
                      r = try_pack_and_write_header(251, bytes)
                    end
                  end
                end
                if r == ''
                  write_int8(0xfc)
                  write_int8(len)
                else
                  to_write = r
                end
              end
            end

            if to_write.is_a?(::String)
              to_write.each_byte { |byte| write_int8(byte) }
            elsif to_write.is_a?(::Array)
              to_write.each { |byte| write_int8(byte) }
            end
          end

          def try_pack_and_write_header(v, data)
            length = data.length
            return '' if length >= 128
            array = [0] * ((length+1)/2).floor
            length.times do | i |
              pack_byte = pack_byte(v, (data[i]).ord)
              if pack_byte == -1
                array = []
                break
              end
              n = (i / 2).floor
              array[n] |= (pack_byte << 4 * (1 - i % 2))
            end
            if array.size > 0
              if length % 2 == 1
                array[array.size-1] |= 0xF
              end
              string = array.map { |arr| arr.chr }.join
              write_int8(v)
              write_int8(length % 2 << 7 | string.length)
              return string
            end
            ''
          end

        end
      end
    end
  end
end