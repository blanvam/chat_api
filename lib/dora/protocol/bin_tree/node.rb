module Dora
	module Protocol
		module BinTree
			class Node

				attr_accessor :key

				def reset_key
					@key = nil
				end

				def set_key(key)
					@key = key
				end
			end
		end
	end
end