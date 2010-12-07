class BidMailer < ActionMailer::Base
  default_url_options[:host] = "www.ebid.com.ph"
  default :from => "E-Bid Admin <admin@ebid.com.ph>"
  
  def bid_alert(line_item, entry, bids)
    
  end
end
