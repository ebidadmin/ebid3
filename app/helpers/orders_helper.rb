module OrdersHelper
  def payment_due_status(order)
    if order.pay_until < Date.today
      content_tag :p, ("Due Date: #{order.pay_until.strftime("%d %b '%y")} | Overdue: #{pluralize order.days_overdue, 'day'} "), :class => alert_class(order) 
    elsif order.pay_until == Date.today
      content_tag :p, 'Due today!', :class => 'mild-alert'
    else
      content_tag :p, "Payment due: #{order.pay_until.strftime("%d %b '%y")} (#{distance_of_time_in_words(Date.today, order.pay_until)} from now)", :class => notifier_class(order) 
    end
  end
  
  def payment_due_status_for_print(order)
    if order.pay_until < Date.today
      content_tag :p, ("Due Date: #{order.pay_until.strftime("%d %b '%y")} | Overdue: #{pluralize order.days_overdue, 'day'}"), :class => 'due-date'
    elsif order.pay_until == Date.today
      content_tag :p, 'Due today!', :class => 'due-date'
    else
      content_tag :p, "Due Date: #{order.pay_until.strftime("%d %b '%y")} (#{distance_of_time_in_words(Date.today, order.pay_until)} from now)", :class => 'due-date'
    end
  end

  def alert_class(order)
    if order.days_overdue >= 10
      'red-alert'
    elsif order.days_overdue >= 0
      'mild-alert'
    else
      'regular-alert'
    end
  end
  
  def notifier_class(order)
    if order.pay_until < 7.days.from_now.to_date
      'regular-alert strong'
    else
      'comfy-alert'
    end
  end
  
end
