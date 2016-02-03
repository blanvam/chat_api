# encoding: utf-8
require 'chat_api/protocol/bin_tree_node'
require 'chat_api/protocol/token_map'

module Dora
	module Protocol
		class BinTreeNodeWriter < BinTreeNode

			attr_reader :output

			def initialize
				@output = ''
			end

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

			protected

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

			def get_int24(size)
				((size & 0xf0000) >> 16).chr << ((size & 0xff00) >> 8).chr << (size & 0xff).chr
			end

			def parse_int24(b_size)
				b_size.byteslice(0, 1).ord << 16  | b_size.byteslice(1, 1).ord << 8 | b_size.byteslice(2, 1).ord << 0
			end

			def write_token(token)
				if token <= 255 && token >= 0
					write_int8(token)
				else
					raise ChatAPIError('Invalid Token.')
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

			def write_string(tag, packed = false)
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
					write_bytes(tag, packed)
				end
			end

			def write_attributes(attributes)
				unless attributes.nil?
					attributes.each do |key, value|
						write_string(key.to_s)
						write_string(value.to_s, true)
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