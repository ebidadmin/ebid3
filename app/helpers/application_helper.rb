module ApplicationHelper

  def go_to_main_page_link
    if current_user.has_role?('admin')
      admin_index_path
    elsif current_user.has_role?('powerbuyer')
      buyer_main_path('all')
    elsif current_user.has_role?('buyer')
      buyer_main_path(current_user)
    elsif current_user.has_role?('seller')
      seller_main_path(current_user)
    end
  end

  def nav_link(text, page, clas=nil, id = nil) 
    content_tag :li, (link_to text, page, :id => current?(page)), :class=> clas
  end 

  def current?(page_name)
    "current_page" if current_page? page_name
  end

  def menu_link(text, controller, action, id = nil, clas = nil) 
    content_tag(:li, (link_to text, {:controller => controller, :action => action, :user_id => user_id?(id)}, :id => is_current?(controller, action)), :class=> clas )
  end 
  
  def user_id?(id)
    if id.nil?
      current_user
    else
      id
    end
  end
	
  def is_current?(controller, action)
    "current_page" if request.parameters['controller'] == controller && request.parameters['action'] == action
  end

  def page_info(target, sort_order = nil)
    (content_tag :p, page_entries_info(target), :class => 'instruction',:id => "page-info") + 
    (content_tag :p, ('Arranged according to ' + (content_tag :strong, sort_order)).html_safe, :class => 'sorting instruction' unless sort_order.nil? || target.blank?)
  end
  
  ## Helpers for buyer's & seller's dashboard
  def dash_entry_format(id, head, instr, count, dash_link=nil, clas=nil, highlight=nil)
    ("<li id='#{id}' class='dash-entry #{clas}'>
      <strong>#{head}</strong>
    	<span class='instruction'>#{instr}</span>
    	<span class='count #{highlight}'>#{count}</span>
    	#{link_to 'View', dash_link, :class => 'link' if dash_link}
  	</li>").html_safe
  end
  
  def dash_link(link)
    if current_user.has_role?('power_buyer')
      link(params[:user_id])
    else
      link(current_user)
    end 
  end
    
  def delimited(target)
    if target > 0
      number_with_delimiter target
    else
      '-'
    end
  end

  def ph_currency(target)
    if target > 0
      number_to_currency target, :unit => 'P '
    else
      '-'
    end
  end

  def currency(target)
    if target > 0
      number_to_currency target, :unit => ''
    else
      '-'
    end
  end
  
  def percentage(computation)
    if computation > 0
      number_to_percentage computation, :precision => 2
    else
      nil
    end
  end
  
  def percentage3(computation)
    if computation > 0
      number_to_percentage computation, :precision => 3
    else
      'FREE'
    end
  end
  
end
