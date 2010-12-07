class EntryMailer < ActionMailer::Base
  # default_url_options[:host] = "www.ebid.com.ph"
  default :from => "E-Bid Admin <admin@ebid.com.ph>"
  
  def new_entry_alert(entry)
    @entry = entry
    mail(:to => "cymarquez@mac.com", :subject => "New Entry Created")
  end
  
  def online_entry_alert(seller, entry)
    @seller = seller
    @entry = entry
    mail(
      :to => "#{seller.profile.full_name} <#{seller.email}>", 
      :subject => "New Entry is now online: #{entry.vehicle}", 
      :bcc => "cymarquez@ebid.com.ph"
      )
  end
end
