module Dora
  module Generators
    class ResponseNodeGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def generate_ability
        copy_file 'response_node.rb', 'app/models/response_node.rb'
      end
    end
  end
end
