require 'dora/registration/utils'

module Dora
  module Registration
    # Phone class to generate info for a phone number
    class Phone
      attr_reader :mcc, :cc, :number

      def initialize(number)
        dissect_phone(number)
      end

      def country_code
        @iso_3166_code
      end

      def lang_code
        @iso_639_code
      end

      def mnc(carrier='')
        detect_mnc(country_code.downcase, carrier) unless carrier.nil?
        @mnc
      end

      private

      def dissect_phone(number)
        country_file = File.join(Dora.data, 'countries.csv')
        if File.exist?(country_file) && File.readable?(country_file)
          CSV.foreach(country_file) do | country, cc, mcc, iso_3166_code, iso_639_code, mnc |
            if number[0, cc.length] == cc
              # Fix country code for North America
              if cc[0] == '1'
                cc = '1'
              end

              @country= country
              @cc= cc
              @number= number[cc.length, number.length]
              @mcc= mcc.split('|')[0]
              @iso_3166_code= iso_3166_code != '' ? iso_3166_code : 'US'
              @iso_639_code= iso_639_code  != '' ? iso_639_code : 'en'
              @mnc= mnc
              return true
            end
          end
        end
        fail ArgumentError.new('The provided phone number is not valid.')
      end

      def detect_mnc(lc, carrier_name)
        @mnc = '000'
        network_info = File.join(Dora.data, 'networkinfo.csv')
        if File.exist?(network_info) && File.readable?(network_info)
          CSV.foreach(network_info) do | data |
            if data[4] == lc && data[7] == carrier_name
              @mnc = data[2]
              break
            end
          end
        end
      end

    end
  end
end