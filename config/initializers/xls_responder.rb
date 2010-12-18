Mime::Type.register "application/vnd.ms-excel", :xls 

ActionController::Renderers.add :xls do |object, options|
  self.send_data object.to_xls_data, :type => :xls
end