module Dora
  module Protocol
    module Stanzas
      module PresenceStanza

        def process_presence(node, *args)
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
            send_clear_dirty(categories)
          end
        end

      end
    end
  end
end