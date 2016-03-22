module Dora
  module Protocol
    ##
    # The JID class represents a Chat_API Identifier.
    #
    # Note that you can use JIDs also for Sorting, Hash keys, ...
    class JID
      include Comparable

      ##
      # Create a new JID. If called as new('a@b'), parse the string and
      # split (node, domain)
      def initialize(jid, name='')
        @name = name
        parts = jid.split('@')
        @number = parts[0]
        @domain = parts[1]
        @domain ||= jid.index('-').nil? ? WHATSAPP_SERVER : WHATSAPP_GROUP_SERVER
      end

      # Get the JID's name
      def name
        @name
      end

      # Set the JID's name
      def name=(v)
        @name = v.to_s
      end

      # Get the JID's number
      def number
        @number
      end

      # Set the JID's number
      def number=(v)
        @number = v.to_s
      end

      # Get the JID's domain
      def domain
        @domain
      end

      # Set the JID's domain
      def domain=(v)
        @domain = v.to_s
      end

      ##
      # Returns a string representation of the JID
      # * "number@domain"
      def to_s
        "#{@number}@#{@domain}"
      end

      ##
      # Returns a hash value of the String representation
      # (see JID#to_s)
      def hash
        to_s.hash
      end

      ##
      # Ccompare to another JID
      #
      # String representations are compared, see JID#to_s
      def eql?(o)
        to_s.eql?(o.to_s)
      end

      ##
      # Ccompare to another JID
      #
      # String representations are compared, see JID#to_s
      def ==(o)
        to_s == o.to_s
      end

      ##
      # Compare two JIDs,
      # helpful for sorting etc.
      #
      # String representations are compared, see JID#to_s
      def <=>(o)
        to_s <=> o.to_s
      end

      # Test if jid is empty
      def empty?
        to_s.empty?
      end
    end

  end

  class ::String
    def to_jid
      if self.index('@').nil?
        #check if group message
        if self.index('-').nil?
          #to normal user
          self << ('@' + Dora::WHATSAPP_SERVER)
        else
          # to group
          self << ('@' + Dora::WHATSAPP_GROUP_SERVER)
        end
      end
      Dora::Protocol::JID.new(self)
    end
  end
end
