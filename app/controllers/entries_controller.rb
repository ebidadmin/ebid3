class EntriesController < ApplicationController
  before_filter :initialize_cart

  def index
    @title = "All Entries"
    if params[:user_id] == 'all'
      @tag_collection = Entry.where(:user_id => current_user.company.users).collect(&:buyer_status).uniq
    else
      @tag_collection = User.find_by_username(params[:user_id]).entries.collect(&:buyer_status).uniq
    end
    initiate_list
    find_entries
    @search = @finder.desc.search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
  end
  
  def show
    @entry = Entry.find(params[:id])
    @line_items = @entry.line_items
  end
  
  def new
    @entry = Entry.new
    2.times {@entry.photos.build}
    @entry.date_of_loss = Date.today
    start_entry
  end
  
  def create
    @entry = Entry.new(params[:entry])
    start_entry
    if @cart.cart_items.blank?
      flash[:error] = "Wait a minute ... your parts selection is still empty!"
      redirect_to new_entry_path
    else
      @entry = Entry.new(params[:entry])
      @entry.add_line_items_from_cart(@cart) 
      if current_user.entries << @entry
        @cart.destroy
        session[:cart_id] = nil 
        flash[:notice] = "Successfully created Entry ID # #{@entry.id}."
        redirect_to @entry
      else
        flash[:error] = "Looks like you forgot to complete the required vehicle info.  Try again!"
        render 'entries/new'
      end
    end
  end
  
  def edit
    if current_user.has_role?('admin')
      @entry = Entry.find(params[:id])
    else
      @entry = current_user.entries.find(params[:id])
    end
    if @entry.photos.first.nil?
      @entry.photos.build
    end
    start_entry
  end
  
  def update
    if current_user.has_role?('admin')
      @entry = Entry.find(params[:id])
    else
      @entry = current_user.entries.find(params[:id])
    end
    @entry.buyer_status = 'Edited'
    @entry.add_line_items_from_cart(@cart) 

    # TODO: UPDATE LINE_ITEMS
    if @entry.update_attributes(params[:entry])
      @cart.destroy
      session[:cart_id] = nil 
      flash[:notice] = "Successfully updated entry."
      redirect_to @entry
    else
      if @entry.photos.first.nil?
        @entry.photos.build
      end
      redirect_to edit_entry_path(@entry)
    end
  end
  
  def destroy
    @entry = Entry.find(params[:id])
    @entry.destroy
    flash[:notice] = "Successfully destroyed entry."
    redirect_to entries_url
  end

  def put_online
    show
    if @entry.update_attributes(:buyer_status => "Online", :bid_until => Date.today + 1.week)
      @entry.update_associated_status("Online")
      flash[:notice] = ("Your entry is <strong>now online</strong>. Thanks!").html_safe
    end
    redirect_to :back
    # for friend in @entry.user.company.friends
    #   unless friend.users.nil?
    #     for user in friend.users
    #       email = user.email
    #       UserMailer.send_later(:deliver_new_entry_notification2friends, email, @entry)
    #     end
    #   end
    # end
  end

  def decide
    show
    unless @entry.bids.blank?
      if @entry.update_attribute(:buyer_status, "For Decision")
        @entry.update_associated_status("For Decision")
        flash[:notice] = ("Great! You can now view the winning bids in your <strong>Results</strong> tab.").html_safe
      end
    else
      flash[:warning] = "You have no quotes to decide on."
    end 
    redirect_to :back
  end
  
  private ##

    def start_entry
      @search = CarPart.name_like_all(params[:name].to_s.split).ascend_by_name
      @car_parts, @car_parts_count = @search.paginate(:page => params[:page], :per_page => 12, :order => 'name ASC'), @search.count
    end

end
