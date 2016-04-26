require 'rest-client'
require 'json'
require 'csv'
require 'tempfile'

require 'active_support/core_ext/object/to_query'

module Dora
  module Registration
    module Utils
      def get_rest_service(host, query)
        url = "#{host}?#{query.to_query}"

        resource = RestClient::Resource.new(
            url,
            :user_agent => WHATSAPP_USER_AGENT,
            :verify_ssl => 0,
            :accept     => 'text/json'
        )

        response = resource.get :user_agent => WHATSAPP_USER_AGENT,
                                :accept => 'text/json'

        JSON.parse(response, symbolize_names: true)
      end

      def process_response(response, default_message)
        status = response[:status]
        if status != 'ok' && status != 'sent'
          case response[:reason]
            when 'too_recent' # get_code
              minutes = (response[:retry_after] / 60).round(2)
              message = "Code already sent. Retry after #{minutes} minutes."
            when 'too_many_guesses' # get_code
              message = 'Too many guesses.'
            when 'bad_token' #get_code
              message = 'Bad token formed'
            when 'blocked' # get_code & check_credentials
              message = 'The number is blocked.'
            when 'incorrect' # check_credentials
              message = 'You have wrong identity. Register number again or copy identity to a file in wadata folder.'
            when 'old_version' # send_code
              update_version
              message = default_message
            else
              message = default_message
          end
          fail RegistrationError.new(message, response)
        end
        response
      end

      def update_version
        data = JSON.parse(open(WHATSAPP_VER_CHECKER).read, symbolize_names: true)
        Dora.update_ver(data)
        Dora::Protocol::Token.update_release_time(data)
      end

      # http://stackoverflow.com/questions/1274605/ruby-search-file-text-for-a-pattern-and-replace-it-with-a-given-value
      def self.file_edit(filename, regexp, replacement)
        temp_dir = File.dirname(filename)
        temp_prefix = File.basename(filename)
        temp_prefix.prepend('.') unless RUBY_PLATFORM =~ /mswin|mingw|windows/
        tempfile =
            begin
              Tempfile.new(temp_prefix, temp_dir)
            rescue
              Tempfile.new(temp_prefix)
            end
        File.open(filename).each do |line|
          tempfile.puts line.gsub(regexp, replacement)
        end
        tempfile.fdatasync unless RUBY_PLATFORM =~ /mswin|mingw|windows/
        tempfile.close
        if RUBY_PLATFORM =~ /mswin|mingw|windows/
          # FIXME: apply perms on windows
        else
          stat = File.stat(filename)
          FileUtils.chown stat.uid, stat.gid, tempfile.path
          FileUtils.chmod stat.mode, tempfile.path
        end
        FileUtils.mv tempfile.path, filename
      end

    end
  end
end