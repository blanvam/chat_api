require 'dora/protocol/bin_tree/writer/base_writer'
require 'dora/protocol/bin_tree/token_map'

module Dora
	module Protocol
		module BinTree
			class NodeWriter < Writer::BaseWriter

				def start_stream(domain, resource)
					attributes = {to: domain, resource: resource}
					write_list_start(attributes.size * 2 + 1)
					write_int8(0x01)
					write_attributes(attributes)
					"WA\x01\x06#{flush_buffer}"
				end

				def write(node, encrypt = true)
					if node.nil?
						write_int8(0x00)
					else
						write_internal(node)
					end
					flush_buffer(encrypt)
				end

				private

				def write_internal(node)
					len = 1
					len += (node.attributes.size * 2) if node.attributes
					len += 1 if node.children && node.children.size > 0
					len += 1 if node.data && node.data.size > 0
					write_list_start(len)
					write_string(node.tag)
					write_attributes(node.attributes)
					if node.data && node.data.size > 0
						write_bytes(node.data)
					end
					if node.children && node.children.size > 0
						write_list_start(node.children.size)
						node.children.each do | child | write_internal(child) end
					end
				end

				def write_list_start(length)
					if length == 0
						write_int8(0)
					elsif length < 256
						write_int8(0xf8)
						write_int8(length)
					else
						write_int8(0xf9)
						write_int16(length)
					end
				end

				def write_string(tag, packed = false)
					found, main, index = TokenMap.try_get_token(tag, false)
					if found
						if main
							write_token(236)
						end
						write_token(index)
						return
					end
					if tag.index('@')
						user, _, server = tag.partition('@')
						write_jid(user, server)
					else
						write_bytes(tag, packed)
					end
				end

				def write_token(token)
					if token <= 255 && token >= 0
						write_int8(token)
					else
						raise ChatAPIError('BinTree::NodeWriter.write_token: Invalid Token.')
					end
				end

				def write_jid(user, server)
					write_int8(0xfa)
					if user.size > 0
						write_string(user, true)
					else
						write_token(0)
					end
					write_string(server)
				end

				def write_attributes(attributes)
					unless attributes.nil?
						attributes.each do |key, value|
							write_string(key.to_s)
							write_string(value.to_s, true)
						end
					end
				end

			end
		end
	end
end