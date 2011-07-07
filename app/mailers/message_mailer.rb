class MessageMailer < ActionMailer::Base
  default :from => "E-Bid Admin <admin@ebid.com.ph>"
  
  def message_alert(entry, message)
    @entry = entry
    @message = message
    unless message.receiver.blank?
      mail(
        :to => "#{message.receiver.profile.full_name} <#{message.receiver.email}>", 
        :subject => "Message Alert: #{entry.vehicle}", 
        :bcc => ["Chris Marquez <cymarquez@ebid.com.ph>", "Efren Magtibay <epmagtibay@ebid.com.ph>"]
        )
    else
      mail(
        :to => "Chris Marquez <cymarquez@ebid.com.ph>", 
        :subject => "OPEN Message Alert: #{entry.vehicle}", 
        )
    end
  end
end
