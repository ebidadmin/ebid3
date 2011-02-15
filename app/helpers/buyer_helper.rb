module BuyerHelper

  ## Helpers for picking low bids in entries#results
  # def high_bid_display(bid_type, item)
  #     ("<td class='bid-box price'> 
  #       #{ render 'bids/bid', :bid => item.high_bid(bid_type) }
  #     </td>").html_safe
  # end
  # 
  # def low_bid_selection(bid_type, item, f)
  #     ("<td class='bid-box price'>
  #       #{ f.radio_button 'id', item.low_bid(bid_type).id unless item.low_bid(bid_type).nil? }
  #       #{ render 'bids/bid', :bid => item.low_bid(bid_type) }
  #     </td>").html_safe
  # end

  def high_bid(bid_type, item)
    render 'bids/bid', :bid => item.high_bid(bid_type)
  end
  
  def low_bid(bid_type, item, f)
		(f.radio_button 'id', item.low_bid(bid_type).id) +	(render 'bids/bid', :bid => item.low_bid(bid_type)) unless item.low_bid(bid_type).nil? 
  end

  def low_bid_no_radiobutton(bid_type, item)
		render 'bids/bid', :bid => item.low_bid(bid_type) unless item.low_bid(bid_type).nil? 
  end

  # helper for buyer fees
  def display_bid_type(fee)
    case fee.bid_type
    when 'original' then type = 'o'
    when 'replacement' then type = 'r'
    when 'surplus' then type = 's'
    end
      
    content_tag :span, type, :class => 'instruction strong'
  end
  
end
