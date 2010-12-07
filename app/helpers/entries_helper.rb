module EntriesHelper
  
  # helpers for cart
  def add_link(car_part)
    link_to "#{car_part.name}  ( + )", cart_add_path(:part_id => car_part), :remote => true
  end
  
  def remove_link(car_part)
    link_to  "(remove)", cart_remove_path(:part_id => car_part), :remote => true
  end
  
  def clear_cart_link
    button_to "Clear Cart", cart_clear_path, :remote => true
  end 

  def parts_total
    unless @entry.new_record?
      pluralize(@entry.line_items.collect(&:quantity).sum + @cart.total, "part") 
    else
      pluralize(@cart.total, "part")
    end
  end
  
  
  def proper_rowspan(item)
    if item.status == "For Decision" 
      # "rowspan = 3" unless item.item_quotes.size < 1
      "rowspan = 2" unless item.bids.size < 1
    end
  end

  def display_status(entry)
    if entry.buyer_status == ("Edited" || "New" || "Online" || "For Decision") 
      ("#{current_status_or_expired?(entry)} #{online_date_status(entry)} | Created: #{entry.created_at.strftime('%b %d')}").html_safe
    else
      ("#{current_status_or_expired?(entry)} (Created: #{entry.created_at.strftime('%b %d')})").html_safe
    end
  end

  def current_status_or_expired?(entry)
    if entry.expired.blank? || entry.buyer_status == "Expired"
      entry.buyer_status
    else
      entry.buyer_status + (content_tag :strong, " - Expired").html_safe 
    end 
  end
  
  def online_date_status(entry)
    # new entries
    if entry.buyer_status == ( "New" || "Edited")
      deadline = entry.created_at + 1.week
      content_tag :strong, "(expiring soon - #{deadline.strftime('%b %d')})" unless deadline > Date.today + 1.week
      
    #online entries
    elsif entry.buyer_status == "Online" 
      if entry.bid_until > Date.today
      "(max #{entry.bid_until.strftime('%b %d')})"
      elsif entry.bid_until == Date.today
        content_tag :strong, "(ending today)"
      elsif entry.expired_at.nil? 
        content_tag :strong, "(bidding ended - expires #{(entry.bid_until + 1.week).strftime('%b %d')})"
      end
      
    #for decision entries
    elsif (entry.buyer_status == "For Decision" || entry.buyer_status == "Ordered-IP") && entry.expired_at.nil?
      deadline = entry.bid_until + 2.weeks
      if Date.today <  deadline - 1.week 
        content_tag :strong, "(display until: #{(deadline).strftime('%b %d')})"
      elsif Date.today < deadline 
        content_tag :strong, "(order now - expires #{(deadline).strftime('%b %d')})"
      elsif Date.today > deadline
        "(deadline lapsed)"
      end
    end
  end

  def display_number_of_bidders(entry)
    count = entry.bids.collect(&:user_id).uniq.count
    if count > 0
      "You have #{pluralize count, 'bidder'} for 
      #{pluralize entry.bids.collect(&:line_item_id).uniq.count, 'item'}"
    else
      "Sorry, no bidders."
    end
  end
  
  ## Helpers for picking low bids in entries#results
  def high_bid_display(bid_type, item)
		("<td class='bid-box price'> 
		  #{ render 'bids/bid', :bid => item.high_bid(bid_type) }
		</td>").html_safe
  end
  
  def low_bid_selection(bid_type, item, f)
		("<td class='bid-box price'>
			#{ f.radio_button 'id', item.low_bid(bid_type).id unless item.low_bid(bid_type).nil? }
			#{ render 'bids/bid', :bid => item.low_bid(bid_type) }
		</td>").html_safe
  end

end
