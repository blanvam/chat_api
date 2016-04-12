# encoding: utf-8
require 'spec_helper'
require 'support/stubs/register.rb'

require 'dora'
require 'dora/registration/register'

describe Dora::Registration::Register, unit: true do
  it 'is available as described_class' do
    expect(described_class).to eq(Dora::Registration::Register)
  end
end

describe Dora::Registration::Register, unit: true do
  before do
    file = File.expand_path('../chat_api/spec/support/identity/id.123456789.dat')
    @register = Dora::Registration::Register.new('34612345678', file)
  end

  it 'correct object created' do
    expect(@register.class).to eq(Dora::Registration::Register)
  end

  it 'get the phone' do
    expect(@register.phone.class).to eq(Dora::Registration::Phone)
  end

  it 'get exception because sms or voice is already sent' do
    path = File.read(File.expand_path(File.join('spec/support/registration/get_code_fail.json')))
    Stubs::Register.get_code(path)

    expect{@register.get_code}.to raise_error(Dora::RegistrationError, /Code already sent. Retry after 179.0 minutes./)
  end

  it 'fail because then token is bad formed' do
    path = File.read(File.expand_path(File.join('spec/support/registration/get_code_bad_token.json')))
    Stubs::Register.get_code(path)

    expect{@register.get_code}.to raise_error(Dora::RegistrationError, /Bad token formed/)
  end

  it 'return exception because the number is blocked' do
    path = File.read(File.expand_path(File.join('spec/support/registration/get_code_blocked.json')))
    Stubs::Register.get_code(path)

    expect{@register.get_code}.to raise_error(Dora::RegistrationError, /The number is blocked./)
  end

  it 'correct get code' do
    path = File.read(File.expand_path(File.join('spec/support/registration/get_code_ok.json')))
    Stubs::Register.get_code(path)

    response = @register.get_code
    er = {status: 'sent', length: 6, method: 'sms', retry_after: 64, sms_wait: 64, voice_wait: 64}
    expect(response).to include(er)
  end

end