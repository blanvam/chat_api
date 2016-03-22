module Stubs
  module Register

    def self.get_code(path)

      regexp = /https:\/\/v.whatsapp.net\/v2\/code\?anhash=\p{XDigit}{32}&cc=34&copiedrc=1&extexist=1&extstate=1&hasinrc=1&id=.{54}&in=612345678&lc=ES&lg=es&mcc=214&method=sms&mistyped=6&mnc=000&network_radio_type=1&pid=\d{1,4}&rchash=\p{XDigit}{64}&rcmatch=1&s=&sim_mcc=214&sim_mnc=000&simnum=1&token=Pv0hrTSPfZw\/TKm60kaAKHaK22w=/n
      WebMock::API.stub_request(:get, regexp).
          with(:headers => {'Accept'=>'text/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'WhatsApp/2.12.440 Android/4.3 Device/Xiaomi-HM_1SW'}).
          to_return(:status => 200, :body => path, :headers => {})

    end

  end
end

