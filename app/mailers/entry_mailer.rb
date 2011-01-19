class EntryMailer < ActionMailer::Base
  # default_url_options[:host] = "www.ebid.com.ph"
  default :from => "E-Bid Admin <admin@ebid.com.ph>"
  
  def new_entry_alert(entry, powerbuyers)
    @entry = entry
    mail(
      :to => powerbuyers,
      :subject => "New Entry Created",
      :bcc => ["Chris Marquez <cymarquez@ebid.com.ph>", "Efren Magtibay <epmagtibay@ebid.com.ph>"] 
      )
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
  
  def comment_alert(entry, comment, recipient=nil)
    @entry = entry
    @comment = comment
    if recipient.blank?
      mail(
        :to => "#{@entry.user.profile.full_name} <#{@entry.user.email}>", 
        :subject => "Comment created: #{entry.vehicle}",
        :bcc => ["Chris Marquez <cymarquez@ebid.com.ph>", "Efren Magtibay <epmagtibay@ebid.com.ph>"] 
        )
    else
      @recipient = recipient
      mail(
        :to => "#{recipient.profile.full_name} <#{recipient.email}>", 
        :subject => "Comment created: #{entry.vehicle}",
        :bcc => ["Chris Marquez <cymarquez@ebid.com.ph>", "Efren Magtibay <epmagtibay@ebid.com.ph>"] 
        )
    end
  end
  
end
