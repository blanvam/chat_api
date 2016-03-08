require 'spec_helper'
require 'chat_api'
require 'dora/registration/token'

describe Dora::Registration::Token, unit: true do
  it 'is available as described_class' do
    expect(described_class).to eq(Dora::Registration::Token)
  end
end

describe Dora::Registration::Token, unit: true do
  before do
    @token = Dora::Registration::Token.new('612345678')
  end

  it 'correct token generation for nokia' do
    expect(@token.generate('Nokia')).to eq('a9c08d6fd9bd80cb8f56652b905805e2')
  end

  it 'correct token generation for android' do
    expect(@token.generate('Android')).to eq('Pv0hrTSPfZw/TKm60kaAKHaK22w=')
  end

  it 'method_missing' do
    expect{@token.generate('method_missing')}.to raise_error(NoMethodError)
  end
end

describe Dora::Registration::Token, unit: true do
  it 'correct token generation for nokia' do
    rel = {'e' => '2.12.440', 'h' => '9999999999999'}
    Dora::Registration::Token.update_release_time(rel)
    expect(Dora::Registration::Token::RELEASE_TIME).to eq('1452554789539')
  end

  it 'correct  RELEASE_TIME' do
    rel = {'e' => '2.12.441', 'h' => '9999999999999'}
    Dora::Registration::Token.update_release_time(rel)
    expect(Dora::Registration::Token::RELEASE_TIME).to eq('9999999999999')
  end

  it 'correct token RELEASE_TIME to default' do
    rel = {'e' => '2.12.41', 'h' => '1452554789539'}
    Dora::Registration::Token.update_release_time(rel)
    expect(Dora::Registration::Token::RELEASE_TIME).to eq('1452554789539')
  end

end