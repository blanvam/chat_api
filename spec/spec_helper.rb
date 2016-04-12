require 'bundler/setup'
Bundler.setup

require 'dora'
require 'webmock/rspec'

RSpec.configure do |config|

  config.before(:suite) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

end

class TCPSocket

  def self.open(host, port)
    new(host, port)
  end

  def initialize(host, port)
    @mock = "mock #{host} #{port}"
    @step = 0
  end

  def closed?
    false
  end

  def sysread(maxlen, buffer)
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