require 'spec_helper'
require 'dora/protocol/bin_tree/token_map'

describe Dora::Protocol::BinTree::TokenMap, unit: true do
  before(:each, specific_specs: true) do
    @tokens = Dora.tokens
  end

  describe 'class' do
    it 'is available as described_class' do
      expect(described_class).to eq(Dora::Protocol::BinTree::TokenMap)
    end
  end

  describe '#read', specific_specs: true do
    it 'correct primary tokens' do
      primary = @tokens['primary'].drop(3)
      primary.each.with_index(3) do |value, index|
        response = Dora::Protocol::BinTree::TokenMap.read(value)
        expect(response).to eq([index, true])
      end
    end

    it 'correct secondary tokens' do
      secondary = @tokens['secondary'].drop(3)
      secondary.each.with_index(3) do |value, index|
        response = Dora::Protocol::BinTree::TokenMap.read(value)
        expect(response).to eq([index, false])
      end
    end

    it 'correct response if cannot parse a token' do
      response = Dora::Protocol::BinTree::TokenMap.read('not_should_found')
      expect(response).to eq([nil, false])
    end

  end

  describe '#parse', specific_specs: true do
    it 'correct primary tokens' do
      primary = @tokens['primary'].drop(3)
      primary.each.with_index(3) do |value, index|
        response = Dora::Protocol::BinTree::TokenMap.parse(index)
        expect(response).to eq([value, true])
      end
    end

    it 'correct secondary tokens' do
      secondary = @tokens['secondary'].drop(236)
      secondary.each.with_index(236) do |value, index|
        response = Dora::Protocol::BinTree::TokenMap.parse(index)
        expect(response).to eq([value, false])
      end
    end

    it 'correct secondary tokens with false' do
      secondary = @tokens['secondary']
      secondary.each_with_index do |value, index|
        response = Dora::Protocol::BinTree::TokenMap.parse(index, false)
        expect(response).to eq([value, false])
      end
    end

    it 'raise error if cannot match a token' do
      primary = @tokens['primary'].length
      secondary = @tokens['secondary'].length
      max = [primary, secondary].max + 1
      expect{Dora::Protocol::BinTree::TokenMap.parse(max)}.to raise_error(Dora::TokenError)
    end

  end

  describe '#parse_primary', specific_specs: true do
    before do
      @primary = @tokens['primary'].drop(3)
    end

    it 'correct primary tokens' do
      @primary.each.with_index(3) do |value, index|
        response = Dora::Protocol::BinTree::TokenMap.parse_primary(index)
        expect(response).to eq(value)
      end
    end

    it 'raise error if cannot match a primary token' do
      max = @primary.length + 3
      expect{Dora::Protocol::BinTree::TokenMap.parse_primary(max)}.to raise_error(Dora::TokenError)
    end

  end

  describe '#parse_secondary', specific_specs: true do
    before do
      @secondary = @tokens['secondary']
    end

    it 'correct secondary tokens' do
      @secondary.each_with_index do |value, index|
        response = Dora::Protocol::BinTree::TokenMap.parse_secondary(index)
        expect(response).to eq(value)
      end
    end

    it 'raise error if cannot match a secondary token' do
      max = @secondary.length + 1
      expect{Dora::Protocol::BinTree::TokenMap.parse_secondary(max)}.to raise_error(Dora::TokenError)
    end

  end

end