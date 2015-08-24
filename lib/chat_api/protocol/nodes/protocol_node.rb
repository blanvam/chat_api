require 'chat_api/protocol/nodes/protocol_node'

module Dora
	module Protocol
		class ProtocolNode

			attr_accessor :data, :tag, :attributes, :children

			def initialize(tag, attributes = nil, children = nil, data = nil)
				@tag = tag
				@attributes = attributes
				@children = children
				@data = data
			end

			def has_child?(tag)
				get_child(tag).nil? ? false : true
			end

			def get_child(tag)
				if @children
					if tag.is_a?(Integer)
						if @children[tag].nil?
							return nil
						else
							return @children[tag]
						end
					end
					@children.each do |child|
						if child.tag == tag
							return child
						end
						ret = child.get_child(tag)
						if ret
							return ret
						end
					end
				end
				nil
			end

			def refresh_times(offset=0)
				if @attributes.has_key?('id') && !@attributes['id'].nil?
					id = @attributes['id']
					parts = id.split('-')
					parts[0] = Time.now.to_i + offset.seconds
					@attributes['id'] = parts.join('-')
				end
				if @attributes.has_key?('id') && !@attributes['t'].nil?
					@attributes['t'] = Time.now.getutc.to_i
				end
			end

		end
	end
end