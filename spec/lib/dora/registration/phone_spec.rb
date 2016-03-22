require 'spec_helper'
require 'dora/registration/phone'

describe Dora::Registration::Phone, unit: true do
  it 'is available as described_class' do
    expect(described_class).to eq(Dora::Registration::Phone)
  end
end

describe Dora::Registration::Phone, unit: true do
  before do
    @phone = Dora::Registration::Phone.new('34612345678')
  end

  it 'create a object' do
    expect(@phone.class).to eq(Dora::Registration::Phone)
  end

  it 'correct number of variables: 7' do
    expect(@phone.instance_variables.size).to eq(7)
  end

  # Variables accessors
  it 'correct mcc' do
    expect(@phone.mcc).to eq('214')
  end

  it 'correct cc' do
    expect(@phone.cc).to eq('34')
  end

  it 'correct number' do
    expect(@phone.number).to eq('612345678')
  end

  # Methods
  it 'correct country_code' do
    expect(@phone.country_code).to eq('ES')
  end

  it 'correct lang_code' do
    expect(@phone.lang_code).to eq('es')
  end

  it 'correct mn' do
    expect(@phone.mnc).to eq('000')
  end

  it 'correct mn with nil' do
    expect(@phone.mnc(nil)).to eq('007')
  end

  it 'correct mn with carrier' do
    expect(@phone.mnc('Vodafone')).to eq('001')
  end

end