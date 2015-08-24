# encoding: utf-8
require 'chat_api/protocol/bin_tree_node'
require 'chat_api/protocol/token_map'

module Dora
	module Protocol
		class BinTreeNodeWriter < BinTreeNode

			attr_reader :output

			def initialize
				@output = '' #.force_encoding(BINARY_ENCODING)
			end

			def start_stream(domain, resource)
				attributes = {to: domain, resource: resource}
				write_list_start(attributes.length * 2 + 1)
				write_int8(0x01)
				write_attributes(attributes)
				"WA\x01\x05#{flush_buffer}"
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
				len += (node.attributes.length * 2) if node.attributes
				len += 1 if node.children && node.children.length > 0
				len += 1 if node.data && node.data.length > 0
				write_list_start(len)
				write_string(node.tag)
				write_attributes(node.attributes)
				write_bytes(node.data) if node.data && node.data.length > 0
				if node.children && node.children.length > 0
					write_list_start(node.children.length)
					node.children.each do | child | write_internal(child) end
				end
			end

			def flush_buffer(encrypt=true)
				size = @output.length
				data = @output.clone
				if !@key.nil? && encrypt
					b_size = ((size & 0xf0000) >> 16).chr << ((size & 0xff00) >> 8).chr << (size & 0xff).chr
					# encrypt
					data = @key.encode_message(data, size, 0, size)
					len = data.length
					b_size[0] = ((8 << 4) | ((len & 16711680) >> 16)).chr
					b_size[1] = ((len & 65280) >> 8).chr
					b_size[2] = (len & 255).chr
					size = b_size.byteslice(0, 1).ord << 16  | b_size.byteslice(1, 1).ord << 8 | b_size.byteslice(2, 1).ord << 0
				end
				result = ((size & 0xff0000) >> 16).chr << ((size & 0x00ff00) >> 8).chr << ((size & 0x0000ff) >> 0).chr << data
				@output.clear
				result
			end

			def write_token(token)
				if token < 0xf5
					write_int8(token)
				elsif token <= 0x1f4
					write_int8(0xfe)
					write_int8(token - 0xf5)
				end
			end

			def write_jid(user, server)
				write_int8(0xfa)
				if user.length > 0
					write_string(user)
				else
					write_token(0)
				end
				write_string(server)
			end

			def write_int8(int)
				@output <<  (int & 0xff).chr
			end

			def write_int16(int)
				@output <<  ((int & 0xff00) >> 8).chr << ((int & 0x00ff) >> 0).chr
			end

			def write_int24(int)
				@output << ((int & 0xff0000) >> 16) << ((int & 0x00ff00) >> 8) << ((int & 0x0000ff) >> 0)
			end

			def write_bytes(bytes)
				len = bytes.length
				if len >= 0x100  #<= 0xff
					write_int8(0xfd)
					write_int24(len)
				else
					write_int8(0xfc)
					write_int8(len)
				end
				if bytes.is_a?(::String)
					bytes.each_byte { |byte| write_int8(byte) }
				elsif bytes.is_a?(::Array)
					bytes.each { |byte| write_int8(byte) }
				end
			end

			def write_string(tag)
				found, main, index = Dora::Protocol::TokenMap.try_get_token(tag, false)
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
					write_bytes(tag)
				end
			end

			def write_attributes(attributes)
				unless attributes.nil?
					attributes.each do |key, value|
						write_string(key.to_s)
						write_string(value.to_s)
					end
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
		end
	end
end