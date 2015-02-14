require 'china_sms'
class Devise::SmsSender
  #Actually sends the sms token. feel free to modify and adapt to your provider and/or gem
  def self.send_sms(phone,message)
    # send_result = self.service.to phone, message, username: '0SDK-EAA-6688-JEWNN', password: '335900'
    puts "#{phone}:#{message}"
    # return send_result[:success]
    return 'fine'
  end

  def self.service
    @@service ||= ChinaSMS::Service::Emay
  end
end
