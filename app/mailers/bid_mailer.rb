class BidMailer < ActionMailer::Base
  helper :application
  
  default_url_options[:host] = "www.ebid.com.ph"
  default :from => "E-Bid Admin <admin@ebid.com.ph>"
  
  def bid_alert(bids, entry)
    @bids = bids
    @entry = entry
    # if entry.user.company.id == 7
    #   mail(
    #     :to => ["Oliver Hambre <oohambre@bpims.com>", "#{entry.user.profile.full_name} <#{entry.user.email}>"],
    #     :subject => "NEW Bids: #{entry.vehicle}", 
    #     :bcc => "Chris Marquez <cymarquez@ebid.com.ph>"
    #     )
    # else
      mail(
        :to => "#{entry.user.profile.full_name} <#{entry.user.email}>", 
        :subject => "NEW Bids: #{entry.vehicle}", 
        :bcc => "Chris Marquez <cymarquez@ebid.com.ph>"
        )
    # end
  end
  
  def bid_alert_to_admin(bids, entry, seller, update = nil)
    @bids = bids
    @entry = entry
    @seller = seller
    
    if update.nil?
      mail(
        :to => ["Chris Marquez <cymarquez@ebid.com.ph>", "Efren Magtibay <epmagtibay@ebid.com.ph>"], 
        :subject => "NEW Bids: #{seller.company.name} > #{entry.vehicle}"
        )
    else
      mail(
        :to => ["Chris Marquez <cymarquez@ebid.com.ph>", "Efren Magtibay <epmagtibay@ebid.com.ph>"], 
        :subject => "UPDATED Bids: #{seller.company.name} > #{entry.vehicle}"
        )
    end  
  end

  
end
