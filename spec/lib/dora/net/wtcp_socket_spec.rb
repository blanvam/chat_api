require 'spec_helper'
require 'dora/net/wtcp_socket'

describe Dora::Net::WTCPSocket, unit: true do
  describe 'class' do
    it 'is available as described_class' do
      expect(described_class).to eq(Dora::Net::WTCPSocket)
    end
  end

  describe '#connected?', unit: true do
    before do
      @socket = Dora::Net::WTCPSocket.new('e1.whatsapp.net', Dora::PORT, Dora::TIMEOUT_SEC, Dora::TIMEOUT_SEC)
    end

    it 'check socket is not connected' do
      expect(@socket.connected?).to eq(false)
    end
  end

  describe '#closed?', unit: true do
    before do
      @socket = Dora::Net::WTCPSocket.new('e1.whatsapp.net', Dora::PORT, Dora::TIMEOUT_SEC, Dora::TIMEOUT_SEC)
    end

    it 'check socket is closed' do
      expect(@socket.closed?).to eq(true)
    end
  end

end