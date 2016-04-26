require 'spec_helper'
require 'dora/net/wtcp_client'
require 'dora/net/wtcp_socket'

describe Dora::Net::WTCPClient, unit: true do
  before do
    allow(Dora::Net::WTCPSocket).to receive(:new).and_return(FakeWTCPSocket.new)
  end

  describe 'class' do
    it 'is available as described_class' do
      expect(described_class).to eq(Dora::Net::WTCPClient)
    end
  end

  describe '#connected?', unit: true do
    before do
      @socket = Dora::Net::WTCPClient.new
    end

    it 'must return false' do
      allow_any_instance_of(FakeWTCPSocket).to receive(:connected?).and_return(false)
      expect(@socket.connected?).to eq(false)
    end

    it 'must return true' do
      allow_any_instance_of(FakeWTCPSocket).to receive(:connected?).and_return(true)
      expect(@socket.connected?).to eq(true)
    end
  end

  describe '#logged?', unit: true do
    before do
      @socket = Dora::Net::WTCPClient.new
      allow_any_instance_of(FakeWTCPSocket).to receive(:connected?).and_return(true)
    end

    it 'must return false by default' do
      expect(@socket.logged?).to eq(false)
    end

    it 'must return true after log_in' do
      @socket.log_in
      expect(@socket.logged?).to eq(true)
    end

    it 'must return true after log_in and false after log_out' do
      @socket.log_in
      expect(@socket.logged?).to eq(true)
      @socket.log_out
      expect(@socket.logged?).to eq(false)
    end

  end

end