class EntryMailer < ActionMailer::Base
  # default_url_options[:host] = "www.ebid.com.ph"
  default :from => "E-Bid Admin <admin@ebid.com.ph>"
  
  def new_entry_alert(entry)
    @entry = entry
    if entry.user.company.id == 7
      mail(
        :to => ["Oliver Hambre <oohambre@bpims.com>", "#{entry.user.profile.full_name} <#{entry.user.email}>"],
        :subject => "New Entry: #{entry.vehicle}",
        :bcc => ["Chris Marquez <cymarquez@ebid.com.ph>", "Efren Magtibay <epmagtibay@ebid.com.ph>"] 
        )
    else
      mail(
        :to => ["Chris Marquez <cymarquez@ebid.com.ph>", "Efren Magtibay <epmagtibay@ebid.com.ph>"],
        :subject => "New Entry: #{entry.vehicle}" 
        )
    end
  end
  
  def online_entry_alert(seller, entry)
    @seller = seller
    @entry = entry
    mail(
      :to => "#{seller.profile.full_name} <#{seller.email}>", 
      :subject => "Now ONLINE: #{entry.vehicle}", 
      :bcc => "cymarquez@ebid.com.ph"
      )
  end

  # def online_entry_alert(friends, entry)
  #   @friends = friends
  #   @entry = entry
  #   mail(
  #     :bcc => friends, 
  #     :subject => "New Entry is now online: #{entry.vehicle}", 
  #     :bcc => "cymarquez@ebid.com.ph"
  #     )
  # end
  
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
