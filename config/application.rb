require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env) if defined?(Bundler)

module Ebid
  class Application < Rails::Application
    config.autoload_paths += %W(#{config.root}/presenters)
    config.time_zone = 'Hong Kong'
    config.action_view.javascript_expansions[:defaults] = %w(jquery rails jquery-ui.min)
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    
    Dir.glob("./lib/*.{rb}").each { |file| require file }
    
    # config.middleware.use ::ExceptionNotifier,
    #   :email_prefix => "E-Bid Errors: ",
    #   :sender_address => %w{E-Bid Admin <admin@ebid.com.ph>},
    #   :exception_recipients => %w{cymarquez@ebid.com.ph}
    
  end
end

