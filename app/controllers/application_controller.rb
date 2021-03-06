class ApplicationController < ActionController::Base
  # include RoleSystem
  protect_from_forgery
  before_filter :authenticate_user!
  # layout 'redesign'

  private

    def after_sign_in_path_for(resource_or_scope)
      if current_user.has_role?('admin')
        admin_index_path 
      elsif current_user.has_role?('powerbuyer')
        buyer_main_path('all') 
      elsif current_user.has_role?('buyer')
        buyer_main_path(current_user) 
      elsif current_user.has_role?('seller')
        seller_main_path(current_user) 
      else
        flash[:info] = "User-privileges not established. Please contact the administrator at 892-5935." 
        root_path
      end
    end

    def after_sign_out_path_for(resource_or_scope)
      new_user_session_path
    end

    def sign_out(resource_or_scope=nil)
      if session[:cart_id]
        unless Cart.where(:id => session[:cart_id]).blank?
          @cart = Cart.find(session[:cart_id])
          @cart.destroy unless @cart.nil?
        end
        session[:cart_id] = nil
      end
      return sign_out_all_scopes unless resource_or_scope
      scope = Devise::Mapping.find_scope!(resource_or_scope)
      warden.user(scope) # Without loading user here, before_logout hook is not called
      warden.raw_session.inspect # Without this inspect here. The session does not clear.
      warden.logout(scope)
    end

    def store_location
      # session[:return_to] = instance['env']["HTTP_REFERER"]
    end
    
    def redirect_back_or_default(default)
      redirect_to (session[:return_to] || default)
      session[:return_to] = nil
    end

  	def check_role(role) 
  	  unless current_user && current_user.has_role?(role) 
  	    flash[:warning] = "Sorry. That page is not included in your access privileges." 
  	    redirect_to root_path
  	  end 
  	end 

  	def check_admin_role 
  	  check_role('admin') 
  	end 

  	def check_buyer_role 
  	  check_role('buyer') 
  	end 

  	def check_seller_role 
  	  check_role('seller') 
  	end 

    def initialize_cart 
      @cart = Cart.find(session[:cart_id]) 
      rescue ActiveRecord::RecordNotFound 
        @cart = Cart.create 
        session[:cart_id] = @cart.id 
    end
    
    # for buyer and entries controllers
    def initiate_list
      if current_user.has_role?("powerbuyer")
        @company_users = current_user.company.users
        @user_group = @company_users.order('username').collect { |user| [user.username_for_menu, request_path(user.username.downcase)] }
        @user_group.push(['All', request_path('all')])
        @current_path = request_path(params[:user_id])
      end
      @status_tags = @tag_collection.collect { |tag| [tag, request_path(:status => tag)] } unless @tag_collection.blank?
      @status_tags.push(['All', request_path(:status => nil)]) unless @tag_collection.blank?
      @status_path = request_path(:status => params[:status])
      unless params[:status].nil?
        @status = params[:status] 
      else
        @status = @tag_collection
      end 
    end

    def request_path(user=nil)
      case request.parameters['action']
      when 'main'
        buyer_main_path(user)
      when 'online'
        buyer_online_path(user)
      when 'pending'
        buyer_pending_path(user) 
      when 'results'
        buyer_results_path(user)
      when 'orders'
        buyer_orders_path(user)
      when 'payments'
        buyer_payments_path(user)
      when 'payments_print'
        buyer_payments_print_path(user)
      when 'paid'
        buyer_paid_path(user)
      when 'fees'
        buyer_fees_path(user)
      when 'index'
        user_entries_path(user)
      when 'entries'
        admin_entries_path(user)
      when 'buyer_fees'
        admin_buyer_fees_path(user)
      end
    end

    def defined_user
      if @user_group 
        User.find_by_username(params[:user_id])
      else
        current_user
      end
    end

    def find_entries
      if params[:user_id] == 'all'
        @finder = Entry.where(:user_id => @company_users, :buyer_status => @status).includes(:term, :city, :car_brand, :car_model, :car_variant, :photos, :orders, :user, :bids)
      else
        @finder = defined_user.entries.where(:buyer_status => @status).includes(:term, :city, :car_brand, :car_model, :car_variant, :photos, :orders, :user, :bids)
      end
    end

    def find_orders
      if params[:user_id] == 'all'
        @all_orders = Order.where(:company_id => current_user.company, :status => @status)
      else
        @all_orders = defined_user.orders.where(:status => @status)
      end
      @sellers = User.where(:id => @all_orders.collect(&:seller_id).uniq).includes(:profile => :company).collect { |seller| [seller.company_name, request_path(:seller => seller.id)]}
      @sellers.push(['All', request_path(:seller => nil)]) unless @sellers.blank?
      @sellers_path = request_path(:seller => params[:seller])
    end
    
    # for seller fees
    def start_date
      if params[:start]
        @start_date = params[:start].to_date
      else
        @start_date = Date.today.beginning_of_month #'2011-04-16'.to_date
      end
    end
    
    def end_date
      if params[:end]
        @end_date = params[:end].to_date
      else
        @end_date = Date.today
      end
    end
    
    def seller_company
      if current_user.has_role?('admin') || current_user.has_role?('buyer')
        if params[:seller]
          @seller_company = Company.find(params[:seller]).name
        else
          @seller_company = 'All Suppliers'
        end
      else
        @seller_company = current_user.company_name
      end
    end

    def buyer_company
      if current_user.has_role?('admin') || current_user.has_role?('seller')
        if params[:buyer]
          @buyer_company = Company.find(params[:buyer]).name
        else
          @buyer_company = 'All Buyers'
        end
      else
        @buyer_company = current_user.company.name
      end
    end

    # for dashboards and fees
    def eval_date
      trial_date = current_user.company.trial_start
      if trial_date.present? 
        @eval_date = trial_date
      else
        @eval_date = '2011-04-16'.to_date
      end
    end

end
