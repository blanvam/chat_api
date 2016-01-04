require 'active_support'
require 'CSV'

module Dora
  class Client
    module Utils
      include ActiveSupport::JSON

      def update_version
        data = ActiveSupport::JSON.decode(open(WHATSAPP_VER_CHECKER).read)
        Dora.update_ver(data)
        Dora::Protocol::Token.update_release_time(data)
      end

      def dissect_phone(number)
        country_file = File.join(Dora.data, 'countries.csv')
        unless File.exist?(country_file) && File.readable?(country_file)
          return false
        end

        CSV.foreach(country_file) do | data |
          if number[0, data[1].length] == data[1]
            mcc = data[2].split('|')[0]

            #hook:
            #fix country code for North America
            if data[1][0] == '1'
              data[1] = '1'
            end

            phone = {
                country: data[0],
                cc: data[1],
                phone: number[data[1].length, number.length],
                mcc: mcc,
                ISO3166: data[3],
                ISO639: data[4],
                mnc: data[5]
            }
            return phone
          end
        end
        false
      end

      def detect_mnc(lc, carrier_name)
        network_info = File.join(Dora.data, 'networkinfo.csv')
        return '000' unless File.exist?(network_info) && File.readable?(network_info)
        mnc = nil
        CSV.foreach(network_info) do | data |
          if data[4] == lc && data[7] == carrier_name
            mnc = data[2]
            break
          end
        end
        mnc = '000' if mnc.nil?
        mnc
      end

    end
  end
end