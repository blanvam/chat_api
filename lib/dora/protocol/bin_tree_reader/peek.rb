module Dora
  module Protocol
    module BinTreeReader
      module Peek

        private

        def peek_int8(offset = 0)
          ret = 0
          if !@input.nil? && @input.length >= (1 + offset)
            ret = @input.byteslice(offset).ord
          end
          ret
        end

        def peek_int16(offset = 0)
          ret = 0
          if !@input.nil? && @input.length >= (2 + offset)
            ret = (@input.byteslice(offset).ord << 8) | @input.byteslice(offset + 1).ord
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

        def peek_int24(offset = 0)
          ret = 0
          if !@input.nil? && @input.length >= (3 + offset)
            ret = (@input.byteslice(offset).ord << 16) | (@input.byteslice(offset + 1).ord << 8) | @input.byteslice(offset + 2).ord
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

      end
    end
  end
end
