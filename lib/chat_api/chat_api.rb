require 'chat_api/version'
require 'chat_api/debug'
require 'chat_api/errors'
require 'chat_api/client'

module Dora

  BINARY_ENCODING         = Encoding.find('binary')      # Encoding::ASCII_8BIT
  UTF8_ENCODING           = Encoding.find('UTF-8')

  MEDIA_FOLDER            = 'media'                      # The relative folder to store received media files
  PICTURES_FOLDER         = 'pictures'                   # The relative folder to store picture files
  DATA_FOLDER             = 'wadata'                     # The relative folder to store cache files.
  PORT                    = 443                          # Port
  TIMEOUT_SEC             = 2                            # The timeout for the connection with the WhatsApp servers.
  WHATSAPP_CHECK_HOST     = 'v.whatsapp.net/v2/exist'    # The check credentials host.
  WHATSAPP_GROUP_SERVER   = 'g.us'                       # The check credentials host.
  WHATSAPP_REGISTER_HOST  = 'v.whatsapp.net/v2/register' # The register code host.
  WHATSAPP_REQUEST_HOST   = 'v.whatsapp.net/v2/code'     # Request host
  WHATSAPP_SERVER         = 's.whatsapp.net'             # Whatsapp server
  WHATSAPP_DEVICE         = 'S40'                        # The device name.
  WHATSAPP_VER            = '2.13.21'                    # Version
  WHATSAPP_USER_AGENT     = 'WhatsApp/2.13.21 S40Version/14.26 Device/Nokia302'        # User agent used in request/registration code.
  WHATSAPP_VER_CHECKER    = 'https://coderus.openrepos.net/whitesoft/whatsapp_scratch' # Check WhatsApp version.


  def Dora.update_ver(data)
    ver = data['e']
    if WHATSAPP_VER != ver
      Dora::Connection.send(:remove_const, 'WHATSAPP_VER') if Dora::Connection.const_defined?('WHATSAPP_VER')
      Dora::Connection.const_set('WHATSAPP_VER', ver)
      Dora::Connection.send(:remove_const, 'WHATSAPP_USER_AGENT') if Dora::Connection.const_defined?('WHATSAPP_USER_AGENT')
      Dora::Connection.const_set('WHATSAPP_USER_AGENT', "WhatsApp/'#{ver} S40Version/14.26 Device/Nokia302")
    end
  end

end