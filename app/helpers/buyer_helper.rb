module BuyerHelper

  ## Helpers for picking low bids in entries#results
  def high_bid(bid_type, item)
    render 'bids/total', :bid => item.high_bid(bid_type)
  end
  
  def low_bid(bid_type, item, f)
		(f.radio_button 'id', item.low_bid(bid_type).id) +	(render 'bids/total', :bid => item.low_bid(bid_type)) unless item.low_bid(bid_type).nil? 
  end

  def low_bid_no_radiobutton(bid_type, item)
      render 'bids/total', :bid => item.low_bid(bid_type) unless item.low_bid(bid_type).nil? 
  end
  
  
  ## Helpers to show item status in entries#show
  def show_item_status_and_links(item)
    if (item.status == "Online" || item.status == "Relisted") && item.bids.present?
      "#{content_tag :span, item.status} (bids are hidden)".html_safe
    else
      "#{content_tag :span, item.status} as of #{show_links(item)}".html_safe
    end
  end
  
  def show_links(item)
    case item.status
    when "PO Released" || "Ordered"
      "#{regular_date item.order.created_at} #{link_to "(view order # #{item.order.id} )", order_path(item.order)}"
    when "For Delivery" || "For-Delivery"
      "#{regular_date item.order.confirmed} #{link_to "(view order # #{item.order.id} )", order_path(item.order)}"
    when "Delivered"
      "#{regular_date item.order.delivered} #{link_to "(view order # #{item.order.id} )", order_path(item.order)}"
    when "Paid"
      "#{regular_date item.order.paid} #{link_to "(view order # #{item.order.id} )", order_path(item.order)}"
    when "Closed"
      "#{regular_date item.order.paid  unless item.order.paid.nil?} #{link_to "(view order # #{item.order.id} )", order_path(item.order) unless item.order.nil?}"
    else
      "#{regular_date item.updated_at}"
    end
  end
end
