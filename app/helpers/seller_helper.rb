module SellerHelper
  def online_or_relisted?(entry) # used in seller#hub
    if entry.buyer_status == 'Relisted'
      content_tag :strong, entry.buyer_status
    else
      entry.buyer_status
    end
  end
    
  def bid_ref(bid_type, item)
    last_bid = item.bids.where(:user_id => current_user, :bid_type => bid_type).last
    ("<div class='bid-field' id='regular'>
  		<p class='bid-amounts' id='#{bid_type}_for_item_#{item.id}'>
  		   #{ render 'bid_reflection', :object => last_bid unless last_bid.nil? }
  		</p>
  		<p class='bid-amounts #{quote_class(last_bid.status) unless last_bid.nil?}'>#{ last_bid.status unless last_bid.nil? }</p>
  	</div>").html_safe
  end

  def quote_class(status)
    if status == "Paid" || status == "Ordered" || status == "PO Released" || status == "Delivered" || status == "For-Delivery" || status == "For Delivery" || status == "Closed"
      "green"
    elsif status == "For Decision" || status == "For-Decision"
      "brown"
    elsif status == "Declined" 
      "orange"
    elsif status == "Lose" 
      "offwhite"
    elsif status == "Updated" 
      "white"
    else
      "just-border"
    end
  end

end
