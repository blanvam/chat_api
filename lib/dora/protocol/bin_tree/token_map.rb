require 'yaml'
module Dora
  module Protocol
    module BinTree
      class TokenMap
        def self.read(string)
          secondary = true
          index = tokens['primary'].index(string)
          unless index
            index = tokens['secondary'].index(string)
            secondary = false
          end
          [index, secondary]
        end

        def self.parse(idx, primary=true)
          if primary && idx >= 236 && idx < (236 + tokens['secondary'].length)
            primary = false
          end
          tag = primary ? parse_primary(idx) : parse_secondary(idx)
          [tag, primary]
        end

        def self.parse_primary(idx)
          token_map = tokens['primary']
          parse_token(token_map, idx)
        end

        def self.parse_secondary(idx)
          token_map = tokens['secondary']
          parse_token(token_map, idx)
        end

        private

        def self.parse_token(token_map, idx)
          if idx < 0 or idx > token_map.length
            response = nil
          else
            response = token_map[idx]
          end
          if response.nil?
            fail TokenError.new('Invalid token/length in TokenMap.parse')
          end
          response
        end

        def self.tokens
          @tokens ||= YAML.load_file 'lib/dora/protocol/bin_tree/tokens.yaml'
        end

      end
    end
  end
end