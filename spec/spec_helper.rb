require 'bundler/setup'
Bundler.setup

require 'chat_api'
require 'webmock/rspec'

RSpec.configure do |config|

  config.before(:suite) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

end