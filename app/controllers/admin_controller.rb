class AdminController < ApplicationController
  def index
    @title = 'Admin Dashboard'
    @entries = Entry.scoped
    @line_items = LineItem.scoped
    @with_bids = @line_items.with_bids
    @with_bids_pct = @line_items.with_bids_pct
    @two_and_up = @line_items.two_and_up
    @two_and_up_pct = @line_items.two_and_up_pct
    @without_bids = @line_items.without_bids

    @online_entries =  @entries.online.desc.five 
    @users = User.active
    # @order = Order.all
  end

  def entries
    @title = 'All Entries'
    @user_group = Role.find_by_name('buyer').users.order('username').collect { |user| [user.username_for_menu, admin_entries_path(:user_id => user.username.downcase)] }
    @user_group.push(['All', admin_entries_path(:user_id => nil)])
    @current_path = admin_entries_path(params[:user_id])
    entries = Entry.scoped
    
    if params[:user_id]
      @search = entries.where(:user_id => User.find_by_username(params[:user_id])).search(params[:search])
    else
      @search = entries.search(params[:search])
    end
    @entries = @search.desc.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'
  end

  def online
    @search = Entry.online.current.desc.search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'  
  end

  def bids
    @search = Bid.desc.search(params[:search])
    @bids = @search.paginate :page => params[:page], :per_page => 10    
    render 'bids/index' 
  end
end
