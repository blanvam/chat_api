module Dora
  class ProcessNode
    # Redefine response for the messages received. For example:
    #
    # See the wiki for details:
    # https://github.com/asfarto/dora/wiki/responde_node

    def self.receipt(node)
      from = node.attributes['from']
      id = node.attributes['id']
      type = node.attributes['type']
      t = node.attributes['t']
      participant = node.attributes['participant']
      offline = node.attributes['offline']
      retries = node.attributes['retry']
      if node.has_child?('list')
        node.get_child('list').children.each do | child |
          from = child.attributes['from']
          id = child.attributes['id']
          type = child.attributes['type']
          t = child.attributes['t']
          participant = child.attributes['participant']
        end
      end
    end

    def self.message(node, type = nil, group = false)
      case type
        when nil
          text = node.get_child('body')
          text = text.data
          notify = node.attributes['notify']
          puts "- #{notify}: #{text}\t\t #{DateTime.now.strftime('%Y-%m-%d - %I:%M:%S %p')}"
        else

      end
    end

    def self.message_received(node) end
    def self.dirty(node) end
    def self.payment_received(node) end
    def self.offline(node) end

    def self.presence?(node)
      availability = node.attributes['type'].nil? ? 'available' : 'unavailable'
      from = node.attributes['from']
      if availability == 'available'
        puts "- #{extract_number(from)} is online"
      else
        puts "- #{extract_number(from)} is offline"
      end
    end

    def self.group_participants_add(node, group_id, parse_jid) end
    def self.group_participants_remove(node, group_id, parse_jid) end
    def self.pong(node)
      id = node.attributes['id']
    end

    def self.synchronized(node)
      #sync result
      sync = node.get_child('sync')
      existing = sync.get_child('in')
      non_existing = sync.get_child('out')

      #process existing first
      existing_users = {}
      unless existing.nil?
        existing.children.each do | child|
          existing_users[child.data] = child.attributes['jid']
        end
      end

      #now process failed numbers
      failed_numbers = {}
      unless non_existing.nil?
        non_existing.children.each do | child|
          failed_numbers << child.data.gsub!('+', '')
        end
      end
    end

    def self.privacy_blocked_list(node)
      list_child = node.get_child(0).get_child(0)
      blocked_jids = []
      list_child.children.each do | child |
        blocked_jids << child.attributes['value']
      end
    end

    def self.request_last_seen(node)
      from = node.attributes['from']
      id = node.attributes['id']
      seconds = node.get_child(0).attributes['seconds']
    end

    def self.server_properties(node)
      props = {}
      node.get_child(0).children.each do | child |
        props[child.attributes['name']] = child.attributes['value']
      end
      version = node.get_child(0).attributes['version']
    end

    def self.profile_image(node) end
    def self.group_created(node) end
    def self.group_left(node) end
    def self.group_info(group_node, from_get_groups = false)
      creator = group_node.attributes['creator']
      creation = group_node.attributes['creation']
      subject = group_node.attributes['subject']
      group_id = group_node.attributes['id']
      participants = []
      admins = []
      unless group_node.get_child(0).nil?
        group_node.children do | child |
          participants << child.attributes['jid']
          if child.attributes['type'] == 'admin'
            admins << child.attributes['jid']
          end
        end
      end
    end
    def self.group_list(node, group_list) end
    def self.broadcast_lists(node)
      broadcast_lists = {}
      unless node.get_child(0).nil?
        child_array = node.children
        child_array.each do |list |
          unless list.children.nil?
            list.children.each do |sublist|
              id = sublist.attributes['id']
              name = sublist.attributes['name']
              broadcast_lists[id] = {name: name }
              recipients = []
              sublist.children.each do | recipient|
                recipients << recipient.attributes['jid']
              end
              broadcast_lists[id] = {recipients: recipients }
            end
          end
        end
      end
    end
    def self.service_pricing(node) end
    def self.extend_account(node) end
    def self.normalized_jid(node) end
    def self.status(node, id) end
    def self.error(node, error_type) end

    def self.ack(node)
      from = node.attributes['from']
      id = node.attributes['id']
      clas = node.attributes['class']
      t = node.attributes['t']
    end

    def self.chatstate(node, type)
      x = 1
    end

    def self.notification(node, type, action = nil)
      case type
        when 'status'
          from = node.attributes['from']
          tag = node.get_child(0).tag
          id = node.attributes['id']
          t = node.attributes['t']
          data = node.get_child(0).data
        when 'picture'
          from = node.attributes['from']
          id = node.attributes['id']
          t = node.attributes['t']
          case type
            when 'set'
            when 'delete'
            else
          end
        when 'contacts'
          notification = node.get_child(0).tag
          jid = node.get_child(0).attributes['jid']
          case notification
            when 'add'
            when 'remove'
            when 'update'
            else
          end
        when 'encrypt'
          value = node.get_child(0).attributes['value']
        when 'group'
          notification_group(node, action)
        when 'account'
          author = node.get_child(0).attributes['author'] == '' ? 'Paypal' : node.get_child(0).attributes['author']
          kind = node.get_child(0).get_child(0).attributes['kind']
          status = node.get_child(0).get_child(0).attributes['status']
          creation = node.get_child(0).get_child(0).attributes['creation']
          expiration = node.get_child(0).get_child(0).attributes['expiration']
        when 'features'
          case action
            when 'encrypt'
              from = node.attributes['from']
              value = node.get_child(0).get_child(0).attributes['value']
            else
          end
        when 'web'
          case action
            when 'sync'
              data = node.get_child(0).children
              from = node.attributes['from']
              id = node.attributes['id']
            else
          end
        else

      end
    end

    def self.call(node, type)
      case type
        when 'offer'
          from = node.attributes['from']
          id = node.attributes['id']
          notify = node.attributes['notify']
          t = node.attributes['t']
          call_id = node.get_child(0).attributes['call-id']
        else

      end
    end

    def self.media_upload_failed(node, id, message_node, message) end
    def self.media_message_sent(node, to, id, file_type, url, file_name, file_size, file_hash, caption, icon) end

    private

    def self.notification_group(node, action)
      case action
        when 'participant_removed'
          from = node.attributes['from']
          jid = node.get_child(0).get_child(0).attributes['jid']
        when 'participant_added'
          from = node.attributes['from']
          jid = node.get_child(0).get_child(0).attributes['jid']
        when 'created'
          creator = node.get_child(0).get_child(0).attributes['creator']
          id = node.get_child(0).get_child(0).attributes['id']
          subject = node.get_child(0).attributes['subject']
          participant = node.attributes['participant']
          creation = node.get_child(0).get_child(0).attributes['creation']
          group_members = []
          node.get_child(0).get_child(0).children do |cn |
            group_members <<  cn.attributes['jid']
          end
        when 'subject'
          from = node.attributes['from']
          t = node.attributes['t']
          participant = node.attributes['participant']
          notify = node.attributes['notify']
        when 'promote'
          from = node.attributes['from']
          t = node.attributes['t']
          participant = node.attributes['participant']
          notify = node.attributes['notify']
          promoted_jid_s = []
          node.get_child(0).children do |cn |
            promoted_jid_s[] = cn.attributes['jid'];
          end
        when 'modify'
          from = node.attributes['from']
          t = node.attributes['t']
          participant = node.attributes['participant']
          notify = node.attributes['notify']
          jid = node.get_child(0).get_child(0).attributes['jid']
        else
      end
    end

    def self.extract_number(from)
      %w(@s.whatsapp.net @g.us).each do |pattern|
        from.gsub!(pattern, '')
      end
      from
    end

  end
end