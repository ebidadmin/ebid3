module AdminHelper
  def active_mark(user)
   if user.current_sign_in_at && user.current_sign_in_at > 1.hour.ago
     image_tag '/images/base/yes.png'
	 end
  end
end
