module SellerHelper
  
  # helper for seller#main
  def percentage(computation)
    if computation > 0
      number_to_percentage computation, :precision => 1
    else
      nil
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
    if status == "Paid" || status == "Ordered" || status == "Delivered" || status == "For Delivery"
      "green"
    elsif status == "For Decision"  
      "brown"
    elsif status == "Declined" 
      "white"
    elsif status == "Lose" 
      "offwhite"
    end
  end

end
