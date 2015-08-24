# encoding: utf-8
module Dora
	module Protocol
		class BinTreeNode

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

