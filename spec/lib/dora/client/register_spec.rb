# encoding: utf-8
require 'spec_helper'
require 'chat_api'
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

  it 'fail get code, already sent' do
    regexp = /https:\/\/v.whatsapp.net\/v2\/code\?anhash=\p{XDigit}{32}&cc=34&copiedrc=1&extexist=1&extstate=1&hasinrc=1&id=.{54}&in=612345678&lc=ES&lg=es&mcc=214&method=sms&mistyped=6&mnc=000&network_radio_type=1&pid=\d{1,4}&rchash=\p{XDigit}{64}&rcmatch=1&s=&sim_mcc=214&sim_mnc=000&simnum=1&token=Pv0hrTSPfZw\/TKm60kaAKHaK22w=/n
    stub_request(:get, regexp).
        with(:headers => {'Accept'=>'text/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'WhatsApp/2.12.440 Android/4.3 Device/Xiaomi-HM_1SW'}).
        to_return(:status => 200, :body => File.read(File.expand_path(File.join('spec/support/registration/get_code_fail.json'))), :headers => {})

    expect{@register.get_code}.to raise_error(Dora::RegistrationError, /Code already sent. Retry after 179.0 minutes./)
  end

  it 'fail get code, token bad formed' do
    regexp = /https:\/\/v.whatsapp.net\/v2\/code\?anhash=\p{XDigit}{32}&cc=34&copiedrc=1&extexist=1&extstate=1&hasinrc=1&id=.{54}&in=612345678&lc=ES&lg=es&mcc=214&method=sms&mistyped=6&mnc=000&network_radio_type=1&pid=\d{1,4}&rchash=\p{XDigit}{64}&rcmatch=1&s=&sim_mcc=214&sim_mnc=000&simnum=1&token=Pv0hrTSPfZw\/TKm60kaAKHaK22w=/n
    stub_request(:get, regexp).
        with(:headers => {'Accept'=>'text/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'WhatsApp/2.12.440 Android/4.3 Device/Xiaomi-HM_1SW'}).
        to_return(:status => 200, :body => File.read(File.expand_path(File.join('spec/support/registration/get_code_bad_token.json'))), :headers => {})

    expect{@register.get_code}.to raise_error(Dora::RegistrationError, /Bad token formed/)
  end

  it 'fail get code, blocked' do
    regexp = /https:\/\/v.whatsapp.net\/v2\/code\?anhash=\p{XDigit}{32}&cc=34&copiedrc=1&extexist=1&extstate=1&hasinrc=1&id=.{54}&in=612345678&lc=ES&lg=es&mcc=214&method=sms&mistyped=6&mnc=000&network_radio_type=1&pid=\d{1,4}&rchash=\p{XDigit}{64}&rcmatch=1&s=&sim_mcc=214&sim_mnc=000&simnum=1&token=Pv0hrTSPfZw\/TKm60kaAKHaK22w=/n
    stub_request(:get, regexp).
        with(:headers => {'Accept'=>'text/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'WhatsApp/2.12.440 Android/4.3 Device/Xiaomi-HM_1SW'}).
        to_return(:status => 200, :body => File.read(File.expand_path(File.join('spec/support/registration/get_code_blocked.json'))), :headers => {})

    expect{@register.get_code}.to raise_error(Dora::RegistrationError, /The number is blocked./)
  end

  it 'correct get code' do
    regexp = /https:\/\/v.whatsapp.net\/v2\/code\?anhash=\p{XDigit}{32}&cc=34&copiedrc=1&extexist=1&extstate=1&hasinrc=1&id=.{54}&in=612345678&lc=ES&lg=es&mcc=214&method=sms&mistyped=6&mnc=000&network_radio_type=1&pid=\d{1,4}&rchash=\p{XDigit}{64}&rcmatch=1&s=&sim_mcc=214&sim_mnc=000&simnum=1&token=Pv0hrTSPfZw\/TKm60kaAKHaK22w=/n
    stub_request(:get, regexp).
        with(:headers => {'Accept'=>'text/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'WhatsApp/2.12.440 Android/4.3 Device/Xiaomi-HM_1SW'}).
        to_return(:status => 200, :body => File.read(File.expand_path(File.join('spec/support/registration/get_code_ok.json'))), :headers => {})

    response = @register.get_code
    er = {status: 'sent', length: 6, method: 'sms', retry_after: 64, sms_wait: 64, voice_wait: 64}
    expect(response).to include(er)
  end

end