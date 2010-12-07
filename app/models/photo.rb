class Photo < ActiveRecord::Base
  belongs_to :entry, :counter_cache => true
 
  has_attached_file :photo,
    :styles => {
      :tiny => ["80x60#", :jpg],
      # :thumb => ["150x113#", :jpg],
      :large => ["640x480>", :jpg]
    },
    :url => "/system/:class/:id/:style/:basename.:extension",
    :path => ":rails_root/public/system/:class/:id/:style/:basename.:extension"
    
 
  # validates_attachment_presence :photo, :message => "^You must upload at least 2 photos."
  validates_attachment_content_type :photo, 
  :content_type => ['image/jpeg', 'image/pjpeg', 
                                   'image/jpg', 'image/png'], :message => "^Acceptable photo formats are jpg, jpeg, or png."
                                   
end
