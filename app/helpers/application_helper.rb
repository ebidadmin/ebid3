module ApplicationHelper

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

  def page_info(target)
    content_tag :p, (page_entries_info target), :class => 'instruction',:id => "page-info"
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
  
end
