ActionMailer::Base.smtp_settings = {
  # :tls => true,
  :address        => 'smtp.gmail.com',
  :port           => 587,
  :domain         => 'www.ebid.com.ph',
  :authentication => :plain,
  :user_name      => 'admin@ebid.com.ph',
  :password       => 'Google12',
  :enable_starttls_auto => true 
}

# ActionMailer::Base.default_url_options[:host] = "www.ebid.com.ph"

ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?
