module DiffsHelper
  def active_diff_mark(entry)
   unless entry.diffs.blank?
     image_tag '/images/base/yes.png'
	 end
  end
end
