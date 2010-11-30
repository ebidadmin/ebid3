module ApplicationHelper

  def nav_link(text, page, clas=nil, id = nil) 
    content_tag :li, (link_to text, page, :id => current?(page)), :class=> clas
  end 

  def current?(page_name)
    "current_page" if current_page? page_name
  end

end
