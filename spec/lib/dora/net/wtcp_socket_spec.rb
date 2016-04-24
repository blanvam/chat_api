require 'spec_helper'
require 'dora/net/wtcp_socket'

describe Dora::Net::WTCPSocket, unit: true do
  it 'is available as described_class' do
    expect(described_class).to eq(Dora::Net::WTCPSocket)
  end
end

describe Dora::Net::WTCPSocket, unit: true do
  before do
    @socket = Dora::Net::WTCPSocket.new('e1.whatsapp.net', Dora::PORT, Dora::TIMEOUT_SEC, Dora::TIMEOUT_SEC)
  end

  it 'create a object' do
    expect(@socket.connected?).to eq(true)
  end

  xit 'create a object' do
    expect(@socket.read(maxlen, buffer)).to eq(true)
  end

end