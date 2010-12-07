module OrdersHelper
  def payment_due_status(order)
    if order.pay_until < Date.today
      content_tag :p, "Overdue: #{order.pay_until.strftime('%b %d')} - #{time_ago_in_words order.pay_until} ago", :class => 'brown' 
    else
      content_tag :strong, "Payment due: #{order.pay_until.strftime('%b %d')}" 
    end
  end
end
