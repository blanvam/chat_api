require 'bundler/setup'
Bundler.setup

require 'dora'
require 'webmock/rspec'
require 'codeclimate-test-reporter'

RSpec.configure do |config|

  config.before(:suite) do
    WebMock.disable_net_connect!(allow_localhost: true, allow: 'codeclimate.com')
  end

end

CodeClimate::TestReporter.start

class FakeWTCPSocket

  def read(maxlen, buffer)
    MOCK_RESPONSES[@step]
    @step = @step + 1
  end

  MOCK_RESPONSES = {
      '0': 'AAAF',
      '1': '+AMBP5s=',
      '2': 'AAAD',
      '3': '+AGp',
      '4': 'AAAZ',
      '5': '+AIY/BRgx8VUPkLkskRXRP/kM/7d8R5e3Q==',
      '6': 'gAA9',
      '7': 'tZL7LPjgnzanyTWdgdvrPurzkWXhF4vWKJCWWTPYItFumDIzlss0HvNHTsQkOq6CvSAfoHeoTg4ouL3hSA=='
  }
end