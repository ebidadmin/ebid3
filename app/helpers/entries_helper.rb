module EntriesHelper
  
  # helpers for cart
  def select_link(car_part, entry = nil)
    (car_part.name + (link_to "select", cart_add_path(:part_id => car_part, :id => entry), :class => 'button', :remote => true)).html_safe
  end
  
  def add_link(car_part, entry = nil)
    link_to "+", cart_add_path(:part_id => car_part, :id => entry), :class => 'add-link', :remote => true
    # (car_part.name + (link_to "+", cart_add_path(:part_id => car_part), :class => 'button', :remote => true)).html_safe
  end

  def remove_link(car_part, entry = nil)
    link_to  "-", cart_remove_path(:part_id => car_part, :id => entry), :class => 'remove-link', :remote => true
  end
  
  def clear_cart_link(entry = nil)
    button_to "Remove Temporary Parts", cart_clear_path(:id => entry), :class => 'red-button', :remote => true
  end 

  def display_status(entry)
    unless entry.buyer_status == "Removed" || entry.buyer_status == "Closed" 
      (content_tag :p, "#{current_status_or_expired?(entry)} #{online_date_status(entry)}".html_safe)
    else
      ("#{current_status_or_expired?(entry)} (Created: #{long_date(entry.created_at)})").html_safe
    end
  end

  def current_status_or_expired?(entry)
    if entry.expired.blank? || entry.buyer_status == "Expired"
      entry.buyer_status
    else
      content_tag :abbr,  "#{entry.buyer_status} #{content_tag :strong, ' - Expired'}".html_safe, :class => 'highlight'
    end 
  end
  
  def online_date_status(entry)
    # new entries
    if entry.buyer_status == "New" || entry.buyer_status == "Edited"
      deadline = entry.created_at + 1.week
      if (deadline - 3.days) >= Date.today
        content_tag :strong, "(expiring soon - #{deadline.strftime('%b %d')})" unless deadline > Date.today + 1.week
      elsif deadline < Date.today
        content_tag :strong, "(lapsed - #{deadline.strftime('%b %d')})"
      end
      
    #online entries
    elsif entry.buyer_status == "Online" || entry.buyer_status == "Relisted"
      if entry.bid_until > Time.now
        "(max #{entry.bid_until.strftime('%b %d')})"
      elsif entry.bid_until == Time.now
        content_tag :strong, "(ending today)"
      elsif entry.expired.nil? 
        content_tag :strong, "(bidding ended - #{entry.bid_until.strftime('%b %d')})"
      end
      
    #for decision entries
    elsif (entry.buyer_status == "For-Decision" || entry.buyer_status == "Ordered-IP" || entry.buyer_status == "Declined-IP") && entry.expired.nil?
      deadline = entry.bid_until + 3.days
      if Time.now <  entry.bid_until  
        "(display until: #{(deadline).strftime('%b %d')})"
      elsif Time.now < deadline 
        content_tag :strong, "(order now - expires #{(deadline).strftime('%b %d')})", :class => 'highlight'
      elsif Time.now == deadline
        content_tag :strong, "(order now - expires today!)", :class => 'highlight'
      elsif Time.now > deadline
        content_tag :strong, "(lapsed - #{deadline.strftime('%b %d')})"
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
  

end
