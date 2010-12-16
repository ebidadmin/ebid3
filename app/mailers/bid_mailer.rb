class BidMailer < ActionMailer::Base
  helper :application
  
  default_url_options[:host] = "www.ebid.com.ph"
  default :from => "E-Bid Admin <admin@ebid.com.ph>"
  
  def bid_alert(bids, entry)
    @bids = bids
    @entry = entry
    mail(
      :to => "#{entry.user.profile.full_name} <#{entry.user.email}>", 
      :subject => "Bid/s submitted: #{entry.vehicle}", 
      :bcc => "Chris Marquez <cymarquez@ebid.com.ph>"
      )
  end
  
  def bid_alert_to_admin(bids, entry, seller)
    @bids = bids
    @entry = entry
    @seller = seller
    mail(
      :to => ["Chris Marquez <cymarquez@ebid.com.ph>", "Efren Magtibay <epmagtibay@ebid.com.ph>"], 
      :subject => "Admin Notice - bid/s submitted: #{entry.vehicle}"
      )
  end
  
end
