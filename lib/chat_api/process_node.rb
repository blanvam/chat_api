module Dora
  class ProcessNode
    def self.process(node)
      case node.tag
        when 'start'
        when 'stream:features'
        when 'challenge'

        when 'failure'

        when 'success'

        when 'stream:error'

        when 'receipt'
          receipt(node)
        when 'message'
          if node.attributes['type'] == 'text' && !node.get_child('body').nil?
            message(node, nil, node.attributes['participant'])
          elsif node.attributes['type'] == 'media' && !node.get_child('media').nil?
            author = node.attributes['participant'].nil?
            message(node, node.get_child('media').attributes['type'], author == '')
          end
          message_received(node) unless node.get_child('received').nil?
        when 'ib'
          node.children.each do | child |
            case child.tag
              when 'dirty'
                dirty(child)
              when 'account'
                payment_received(child)
              when 'offline'
                offline(child)
              else
            end
          end
        when 'presence'
          if node.attributes['status'] == 'dirty'
            #clear dirty
            categories = []
            if node.children.length > 0
              node.children.each do | child|
                if child.tag == 'category'
                  categories << child.attributes('name')
                end
              end
            end
            #connector.send_clear_dirty(categories)
          end
          #if node.attributes['from'][0, @phone_number.length] != @phone_number
            if node.attributes['from'].index('-').nil?
              presence?(node)
            end

            if !node.attributes['from'].index('-').nil? && !node.attributes['type'].nil?
              group_id = parse_jid(node.attributes['from'])
              if !node.attributes['add'].nil?
                group_participants_add(node, group_id, parse_jid(node.attributes['add']))
              elsif !node.attributes['remove'].nil?
                group_participants_remove(node, group_id, parse_jid(node.attributes['remove']))
              end
            end
          #end
        when 'iq'
          if node.attributes['type'] == 'get' && node.attributes['xmlns'] == 'urn:xmpp:ping'
            pong(node)
          end

          unless node.get_child('sync').nil?
            synchronized(node)
          end

          if node.attributes['type'] == 'result'
            unless node.get_child('query').nil?
              if @node_id.has_key?('privacy') && !@node_id['privacy'].nil? && @node_id['privacy'] == node.attributes['id']
                privacy_blocked_list(node)
                return nil
              end
              request_last_seen(node)
            end

            unless node.get_child('props').nil?
              #server properties
              server_properties(node)
            end
            profile_image(node) unless node.get_child('picture').nil?

            unless (node.attributes['from'].index(self.class::WHATSAPP_GROUP_SERVER)).nil?
              #There are multiple types of Group reponses. Also a valid group response can have NO children.
              #Events fired depend on text in the ID field.
              group_list = []
              group_nodes = []
              if !node.get_child(0).nil? && !node.get_child(0).children.nil?
                node.get_child(0).children.each do | child |
                  group_list << child.attributes
                  group_nodes << child
                end
              end
              if !@node_id.nil? && @node_id.has_key?('groupcreate') && !@node_id['groupcreate'].nil? && @node_id['groupcreate'] == node.attributes['id']
                group_created(node)
              end
              if !@node_id.nil? && @node_id.has_key?('leavegroup') && !@node_id['leavegroup'].nil? && @node_id['leavegroup'] == node.attributes['id']
                group_left(node)
              end
              if !@node_id.nil? && @node_id.has_key?('getgroups') && !@node_id['getgroups'].nil? && @node_id['getgroups'] == node.attributes['id']
                #getGroups returns a array of nodes which are exactly the same as from getGroupV2Info
                #so lets call this event, we have all data at hand, no need to call getGroupV2Info for every group we are interested
                group_nodes.each do | group_node |
                  group_info(group_node, true)
                end
                group_list(node, group_list)
              end
              if !@node_id.nil? && @node_id.has_key?('get_groupv2_info') && !@node_id['get_groupv2_info'].nil? && @node_id['get_groupv2_info'] == node.attributes['id']
                group_info(node) unless node.get_child(0).nil?
              end
            end
            if !@node_id.nil? && @node_id.has_key?('get_lists') && !@node_id['get_lists'].nil? && @node_id['get_lists'] == node.attributes['id']
              broadcast_lists(node)
            end
            service_pricing(node) unless node.get_child('pricing').nil?
            extend_account(node) unless node.get_child('extend').nil?
            normalized_jid(node) unless node.get_child('normalize').nil?
            unless node.get_child('status').nil?
              child = node.get_child('status')
              child.children.each do |  status |
                status(status, node.attributes['id'])
              end
            end
          end

          if node.attributes['type'] == 'error'
            error_type=nil
            @node_id.each do | e_type, node_id |
              if node_id == node.attributes['id']
                error_type = e_type
                break
              end
            end
            error(node, error_type)
          end
        when 'ack'
          ack(node) if node.attributes['class'] == 'message'
        when 'chatstate'
          #if node.attributes['from'][0, @phone_number.length] != @phone_number && node.attributes['from'].index('-').nil?
            type = node.get_child(0).tag == 'composing' ? 'composing' : 'paused'
            chatstate(node, type)
          #end
        when 'notification'
          type = node.attributes['type']
          case type
            when 'status'
              notification(node, type)
            when 'picture'
              if node.has_child?('set')
                notification(node, type, 'set')
              elsif node.has_child?('delete')
                notification(node, type, 'delete')
              end
            when 'contacts'
              notification(node, type)
            when 'encrypt'
              value = node.get_child(0).attributes['value']
              if value.is_a?(Integer)
                notification(node, type, 'keys_left')
              else
                puts "Corrupt Stream: value #{value} is not numeric"
              end
            when 'w:gp2'
              if node.has_child?('remove')
                if node.get_child(0).has_child?('participant')
                  notification(node, 'group', 'participant_removed')
                end
              elsif node.has_child?('add')
                notification(node, 'group', 'participant_added')
              elsif node.has_child?('create')
                notification(node, 'group', 'created')
              elsif node.has_child?('subject')
                notification(node, 'group', 'subject')
              elsif node.has_child?('promote')
                notification(node, 'group', 'promote')
              elsif node.has_child?('modify')
                notification(node, 'group', 'modify')
              end
            when 'account'
              notification(node, type, 'paid')
            when 'features'
              if node.get_child(0).get_child(0) == 'encrypt'
                notification(node, type, 'encrypt')
              end
            when 'web'
              if node.get_child(0).tag == 'action' && node.get_child(0).attributes['type'] == 'sync'
                notification(node, type, 'sync')
              end
            when 'creator'
            else
              raise ChatAPIError.new("Method #{type} not implemented")
          end
        when 'call'
          if node.get_child(0).tag == 'offer'
            call(node, 'offer')
          else
            puts " Call - tag: #{node.get_child(0).tag}"
          end
        else
          puts "tag: #{node.tag} not implemented"
      end
    end
  end
end