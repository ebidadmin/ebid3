class MessageMailer < ActionMailer::Base
  default :from => "E-Bid Admin <admin@ebid.com.ph>"
  
  def message_alert(entry, message)
    @entry = entry
    @message = message
    unless message.receiver.blank?
      mail(
        :to => "#{message.receiver.profile.full_name} <#{message.receiver.email}>", 
        :subject => "Message Alert: #{entry.vehicle}", 
        :bcc => ["Chris Marquez <cymarquez@ebid.com.ph>"]
        )
    else
      mail(
        :to => "Chris Marquez <cymarquez@ebid.com.ph>", 
        :subject => "OPEN Message: #{entry.vehicle}", 
        )
    end
  end
  
  def cancelled_order_message(order, message)
    @order = order
    @message = message
    mail(
      :to => ["#{order.user.profile.full_name} <#{order.user.email}>", "#{order.seller.profile.full_name} <#{order.seller.email}>"],
      :subject => "Order CANCELLED",
      :bcc => ["Chris Marquez <cymarquez@ebid.com.ph>", "Efren Magtibay <epmagtibay@ebid.com.ph>"]
    )
  end
end
