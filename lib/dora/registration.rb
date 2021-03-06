require 'dora/registration/register'

module Dora
  module Registration

    def code_request(method = 'sms', carrier = nil)
      set_reg
      @reg.get_code(method, carrier)
    end

    def code_register(code)
      set_reg
      @reg.send_code(code)
    end

    def check_credentials
      set_reg
      @reg.check_credentials
    end

    private

    def set_reg
      @reg ||= Register.new(@jid.number, @path_identity)
    end

  end
end
