require 'chat_api/protocol/nodes/protocol_node'
require 'chat_api/util'

module Dora
	include Util
	module Protocol
		class ProtocolNode

			attr_accessor :data, :tag, :attributes, :children

			def initialize(tag, attributes = nil, children = nil, data = nil)
				@tag = tag
				@attributes = attributes
				@children = children
				@data = data
			end

			def child?(tag)
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

			def to_s(indent = '', is_child = false)
				#formatters
				lt = '<'
				gt = '>'
				nl = "\n"

				ret = indent + lt + @tag
				unless @attributes.nil?
					@attributes.each do |key, value|
						ret +=  ' ' + key.to_s + "=\"" + value.to_s + "\""
					end
				end
				ret += gt

				if !@data.nil? && @data.size > 0
					if @data.size <= 1024
						#message
						if @data.encoding == BINARY_ENCODING
							ret += bin2hex(@data)
						else
							ret += @data
						end
					else
						#raw data
						ret += ' ' + @data.size.to_s + ' byte data'
					end
				end

				unless @children.nil?
					ret += nl
					@children.each do | child |
						ret += child.to_s(indent + ' ', true) + nl
					end
					ret += nl + indent
				end

				ret += lt + '/' + @tag + gt

				unless is_child
					ret += nl
				end

				ret
			end

		end
	end
end