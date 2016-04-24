require 'spec_helper'
require 'dora/registration'
require 'dora/protocol/jid'

describe Dora::Registration, unit: true do
  it 'is available as described_class' do
    expect(described_class).to eq(Dora::Registration)
  end
end

describe Dora::Registration, unit: true do
  include Dora::Registration
  before do
    @path_identity = File.expand_path('../chat_api/spec/support/identity/id.123456789.dat')
    @jid = Dora::Protocol::JID.new('34612345678', 'test')
  end

  it 'correct object created' do
    regexp = /https:\/\/v.whatsapp.net\/v2\/code\?anhash=\p{XDigit}{32}&cc=34&copiedrc=1&extexist=1&extstate=1&hasinrc=1&id=.{54}&in=612345678&lc=ES&lg=es&mcc=214&method=sms&mistyped=6&mnc=007&network_radio_type=1&pid=\d{1,4}&rchash=\p{XDigit}{64}&rcmatch=1&s=&sim_mcc=214&sim_mnc=007&simnum=1&token=\b{28}/n
    stub_request(:get, regexp).
        with(:headers => {'Accept'=>'text/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>Dora::WHATSAPP_USER_AGENT}).
        to_return(:status => 200, :body => File.read(File.expand_path(File.join('spec/support/registration/get_code_ok.json'))), :headers => {})

    response = code_request
    er = {status: 'sent', length: 6, method: 'sms', retry_after: 64, sms_wait: 64, voice_wait: 64}
    expect(response).to eq(er)
  end
end
