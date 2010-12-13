class ApplicationController < ActionController::Base
  # include RoleSystem
  protect_from_forgery
  before_filter :authenticate_user!

  private
    # def stored_location_for(resource_or_scope)
    #   nil
    # end

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
        flash[:notice] = "User-privileges not established." 
        root_path
      end
    end

    def sign_out(resource_or_scope=nil)
      if session[:cart_id]
        @cart = Cart.find(session[:cart_id]) 
        @cart.destroy unless @cart.nil?
        session[:cart_id] = nil
      end
      return sign_out_all_scopes unless resource_or_scope
      scope = Devise::Mapping.find_scope!(resource_or_scope)
      warden.user(scope) # Without loading user here, before_logout hook is not called
      warden.raw_session.inspect # Without this inspect here. The session does not clear.
      warden.logout(scope)
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
      if session[:cart_id]
        @cart = Cart.find(session[:cart_id]) 
      else
        @cart = Cart.create
        session[:cart_id] = @cart.id 
      end  
    end
    
    # helpers for buyer and entries controllers
    def initiate_list
      if current_user.has_role?("powerbuyer")
        @company_users = current_user.company.users
        @user_group = @company_users.order('username').collect { |user| [user.username_for_menu, request_path(user.username.downcase)] }
        @user_group.push(['All', request_path('all')])
        @current_path = request_path(params[:user_id])
      end
      @status_tags = @tag_collection.collect { |tag| [tag, request_path(:status => tag)] } if @tag_collection
      @status_tags.push(['All', request_path(:status => nil)]) if @tag_collection 
      @status_path = request_path(:status => params[:status])
      @status = params[:status] unless params[:status].nil?
      @status = @tag_collection if params[:status].nil?
    end

    def request_path(user)
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
      when 'paid'
        buyer_paid_path(user)
      when 'fees'
        buyer_fees_path(user)
      when 'index'
        user_entries_path(user)
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
        @finder = Entry.where(:user_id => @company_users, :buyer_status => @status)
      else
        @finder = defined_user.entries.where(:buyer_status => @status)
      end
    end

    def find_orders
      if params[:user_id] == 'all'
        @all_orders = Order.where(:company_id => current_user.company, :status => @status)
      else
        @all_orders = defined_user.orders.where(:status => @status)
      end
      @sellers = User.where(:id => @all_orders.collect(&:seller_id).uniq).collect { |seller| [seller.company_name, request_path(:seller => seller.id)]}
      @sellers.push(['All', request_path(:seller => nil)]) unless @sellers.blank?
      @sellers_path = request_path(:seller => params[:seller])
    end
    
end
