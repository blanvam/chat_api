require 'spec_helper'
require 'dora/registration/identity'

describe Dora::Registration::Identity, unit: true do
  it 'is available as described_class' do
    expect(described_class).to eq(Dora::Registration::Identity)
  end
end

describe Dora::Registration::Identity, unit: true do
  before do
    @identity = Dora::Registration::Identity.new('123456789')
  end

  it 'create a object' do
    expect(@identity.class).to eq(Dora::Registration::Identity)
  end

  it ' transform a object into a string' do
    expect(@identity.to_s.size).to eq(20)
  end

  it 'accessor to bytes' do
    expect(@identity.bytes.size).to eq(20)
  end
end

describe Dora::Registration::Identity, unit: true do
  before do
    file = File.expand_path('../chat_api/spec/support/identity/id.123456789.dat')
    @identity = Dora::Registration::Identity.new('123456789', file)
  end

  it 'create indentity form a file' do
    expect(@identity.bytes.unpack('H*').first).to eq('f2905fa12aed0f9c00e39cfc3ad1caeae525d713')
  end

  it 'Correct generation of the bytes string' do
    expect(@identity.to_s.unpack('H*').first).to eq('f2905fa12aed0f9c00e39cfc3ad1caeae525d713')
  end

  it 'Proper access to byte string' do
    expect(@identity.bytes.unpack('H*').first).to eq('f2905fa12aed0f9c00e39cfc3ad1caeae525d713')
  end
end