$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require 'rvm/capistrano'
require "bundler/capistrano"
set :rvm_bin_path, "/usr/local/bin/"

set :application, "ebid"
set :repository,  "git@github.com:ebidadmin/ebid3.git"
set :scm, :git
# set :scm_username, 'chrism'
# set :scm_password, 'Beanstalk21' 

# set :domain, "74.207.254.124"
# set :user, "root" 
# set :use_sudo, false
# set :deploy_to, "/srv/www/ebid.com.ph"
# ssh_options[:forward_agent] = true
# set :branch, "master"
# set :git_shallow_clone, 1
# set :git_enable_submodules, 1
# set :rails_env, "production"
# 
# role :web, "74.207.254.124"                          # Your HTTP server, Apache/etc
# role :app, "74.207.254.124"                          # This may be the same as your `Web` server
# role :db,  "74.207.254.124", :primary => true        # This is where Rails migrations will run

set :domain, "ebidlabs.com"
set :user, "root" 
set :use_sudo, false
set :deploy_to, "/srv/www/ebid.com.ph"
ssh_options[:forward_agent] = true
set :branch, "master"
set :git_shallow_clone, 1
set :git_enable_submodules, 1
set :rails_env, "production"
                                                    
role :web, "ebidlabs.com"                         
role :app, "ebidlabs.com"                         
role :db,  "ebidlabs.com", :primary => true       
                                                    

namespace :deploy do
  desc "Start apache server" 
  task :start, :roles => :app do 
    run "/etc/init.d/apache2 start"
  end 
  
  desc "Stop apache server" 
  task :stop, :roles => :app do
    run "/etc/init.d/apache2 stop"
  end
  
  desc "Restart apache server" 
  task :restart, :roles => :app do
    run "/etc/init.d/apache2 restart"
  end
  
  desc "Track production log" 
  task :tail_log, :roles => :app do 
    stream "tail -f #{shared_path}/log/production.log"
  end
end

namespace :delayed_job do
  desc "Start delayed_job process" 
  task :start, :roles => :app do
    run "cd #{current_path}; script/delayed_job start RAILS_ENV=#{rails_env}" 
  end

  desc "Stop delayed_job process" 
  task :stop, :roles => :app do
    run "cd #{current_path}; script/delayed_job stop RAILS_ENV=#{rails_env}" 
  end

  desc "Restart delayed_job process" 
  task :restart, :roles => :app do
    run "cd #{current_path}; script/delayed_job restart RAILS_ENV=#{rails_env}" 
  end

end

namespace :passenger do
  desc "Restart Application"
  task :restart do
    run "cd #{current_path}; touch tmp/restart.txt" 
  end
end

after "deploy", "passenger:restart"
after "deploy:start", "delayed_job:start" 
after "deploy:stop", "delayed_job:stop" 
after "deploy:restart", "delayed_job:restart"
