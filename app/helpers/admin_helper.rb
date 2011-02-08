module AdminHelper
  def active_mark(user)
   if user.current_sign_in_at && user.current_sign_in_at > 1.hour.ago
     image_tag '/images/base/yes.png'
	 end
  end
  
  ## Helpers for picking low bids in entries#results
  # def admin_high_bid_display(bid_type, item)
  #     ("<td class='bid-box price'> 
  #       #{ render 'admin/bid', :bid => item.high_bid(bid_type) }
  #     </td>").html_safe
  # end
  # 
  # def admin_low_bid_selection(bid_type, item, f)
  #     ("<td class='bid-box price'>
  #       #{ f.radio_button 'id', item.low_bid(bid_type).id unless item.low_bid(bid_type).nil? }
  #       #{ render 'admin/bid', :bid => item.low_bid(bid_type) }
  #     </td>").html_safe
  # end

  def admin_high_bid(bid_type, item)
    render 'admin/bid', :bid => item.high_bid(bid_type)
  end
  
  def admin_low_bid(bid_type, item)
		render 'admin/bid', :bid => item.low_bid(bid_type) unless item.low_bid(bid_type).nil? 
  end
  
end
