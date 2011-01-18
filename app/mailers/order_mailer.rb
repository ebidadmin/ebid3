class OrderMailer < ActionMailer::Base
  # default_url_options[:host] = "www.ebid.com.ph"
  default :from => "E-Bid Admin <admin@ebid.com.ph>"

  def order_alert(orders)
    orders.each do |order|
      @order = order
      mail(
        :to => "#{order.seller.profile.full_name} <#{order.seller.email}>", 
        :subject => "PO Released: #{order.entry.vehicle}", 
        :bcc => ["Chris Marquez <cymarquez@ebid.com.ph>", "Efren Magtibay <epmagtibay@ebid.com.ph>"]
        )
    end
  end
  
  def order_paid_alert(order, entry)
    @order = order
    @entry = entry
    mail(
      :to => "#{order.seller.profile.full_name} <#{order.seller.email}>", 
      :subject => "PO Tagged as 'Paid'", 
      :bcc => ["Chris Marquez <cymarquez@ebid.com.ph>", "Efren Magtibay <epmagtibay@ebid.com.ph>"]
      )
  end
end
