module Dora
  module Protocol
    module BinTree
      module Writer
        module Helper

          private

          def pack_byte(v, n)
            case v
              when 251
                pack_hex(n)
              when 255
                pack_nibble(n)
              else
                -1
            end
          end

          def pack_hex(n)
            case n
              when 48, 49, 50, 51, 52, 53, 54, 55, 56, 57
                n - 48
              when 65, 66, 67, 68, 69, 70
                10 + (n - 65)
              else
                -1
            end
          end

          def pack_nibble(n)
            case n
              when 45, 46
                10 + (n - 45);
              when 48, 49, 50, 51, 52, 53, 54, 55, 56, 57
                n - 48
              else
                -1
            end
          end

        end
      end
    end
  end
end