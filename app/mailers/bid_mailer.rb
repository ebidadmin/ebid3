class BidMailer < ActionMailer::Base
  default_url_options[:host] = "www.ebid.com.ph"
  default :from => "E-Bid Admin <admin@ebid.com.ph>"
  
  def bid_alert(bids, entry)
    @bids = bids
    @entry = entry
    mail(
      :to => "#{entry.user.profile.full_name} <#{entry.user.email}>", 
      :subject => "Bids submitted: #{entry.vehicle}", 
      :bcc => ["Chris Marquez <cymarquez@ebid.com.ph>", "Efren Magtibay <epmagtibay@ebid.com.ph>"]
      )
  end
end
