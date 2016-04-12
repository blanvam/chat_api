require 'dora/protocol/nodes/node'

module Dora
  module Protocol
    module Nodes
      class SyncNode < Node

        def initialize(numbers, deleted_numbers, sync_type, index, last)
          mode, context = SyncNode.mode_context(sync_type)
          attributes = {
              mode: mode,
              context: context,
              sid: ((Time.now.getutc + 11644477200).to_i * 10000000).to_s,
              index: index.to_s,
              last: last ? 'true' : 'false'
          }
          super('sync', attributes, SyncNode.users(numbers, deleted_numbers))
        end

        class << self

          def mode_context(sync_type)
            case sync_type
              when 0
                mode = 'full'
                context = 'registration'
              when 1
                mode = 'full'
                context = 'interactive'
              when 2
                mode = 'full'
                context = 'background'
              when 3
                mode = 'delta'
                context = 'interactive'
              when 4
                mode = 'delta'
                context = 'background'
              when 5
                mode = 'query'
                context = 'interactive'
              when 6
                mode = 'chunked'
                context = 'registration'
              when 7
                mode = 'chunked'
                context = 'interactive'
              when 8
                mode = 'chunked'
                context = 'background'
              else
                mode = 'delta'
                context = 'background'
            end
            return mode, context
          end

          def users(numbers, deleted_numbers)
            users = []
            numbers.length.times do | i |
              users << Node.new('user', nil, nil, (numbers[i][0, 1] != '+') ? ('+' + numbers[i]) : (numbers[i]))
            end
            unless deleted_numbers.nil?
              deleted_numbers.length.times do | j |
                users << Node.new('user', {jid: deleted_numbers[j].to_jid.to_s, type: 'delete'})
              end
            end
          end

        end

      end
    end
  end
end