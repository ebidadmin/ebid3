module PhotosHelper
  def link_to_remove(name, f)
    f.hidden_field(:_destroy) + link_to(name, :remote => true, :class => "remove_nested_fields")
  end

end
