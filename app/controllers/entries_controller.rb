class EntriesController < ApplicationController
  before_filter :initialize_cart, :except => [:index, :show, :put_online, :relist, :decide, :reactivate]

  def index
    @title = "All Entries"
    if params[:user_id] == 'all'
      @tag_collection = Entry.where(:user_id => current_user.company.users).alive.collect(&:buyer_status).uniq
    else
      @tag_collection = User.find_by_username(params[:user_id]).entries.alive.collect(&:buyer_status).uniq
    end
    initiate_list
    find_entries
    @search = @finder.desc.search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
  end
  
  def show
    @entry = Entry.find(params[:id])
    @line_items = @entry.line_items.includes(:car_part)
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
      redirect_to new_user_entry_path(current_user)
    else
      @entry = Entry.new(params[:entry])
      @entry.add_line_items_from_cart(@cart) 
      if current_user.entries << @entry
        @cart.destroy
        session[:cart_id] = nil 
        EntryMailer.delay.new_entry_alert(@entry)
        flash[:notice] = "Successfully created Entry ID # #{@entry.id}."
        redirect_to buyer_pending_path(current_user)
      else
        flash[:error] = "Looks like you forgot to complete the required vehicle info.  Try again!"
        render 'new'
      end
    end
  end
  
  def edit
    if current_user.has_role?('admin')
      session['referer'] = request.env["HTTP_REFERER"]
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
    @entry.buyer_status = 'Edited' unless current_user.has_role?('admin')
    @entry.add_line_items_from_cart(@cart) 

    # TODO: UPDATE LINE_ITEMS
    if @entry.update_attributes(params[:entry])
      @cart.destroy
      session[:cart_id] = nil 
      flash[:notice] = "Successfully updated entry."
      if current_user.has_role?('admin')
        redirect_to session['referer'] #redirect_to user_ratings_path(current_user)
        session['referer'] = nil
      else
        redirect_to buyer_pending_path(current_user)
      end
    else
      if @entry.photos.first.nil?
        @entry.photos.build
      end
      render 'edit'
    end
  end
  
  def destroy
    if current_user.has_role?('admin')
      @entry = Entry.find(params[:id])
      @entry.destroy
    else
      @entry = current_user.entries.find(params[:id])
      @entry.update_attribute(:buyer_status, "Removed")
      @entry.line_items.update_all(:status => "Removed")
    end
    flash[:notice] = "Successfully deleted entry."
    redirect_to :back #user_entries_path(current_user)
  end

  def put_online
    show
    if @entry.update_attributes(:buyer_status => "Online", :bid_until => Date.today + 1.week)
      @entry.update_associated_status("Online")
      flash[:notice] = ("Your entry is <strong>now online</strong>. Thanks!").html_safe
    end
    redirect_to :back
    for friend in @entry.user.company.friends
      unless friend.users.nil?
        for seller in friend.users
          EntryMailer.delay.online_entry_alert(seller, @entry)
        end
      end
    end
  end

  def decide
    show
    unless @entry.bids.blank?
      if @entry.update_attribute(:buyer_status, "For-Decision")
        @entry.update_associated_status("For-Decision")
        flash[:notice] = ("Great! You can now view the winning bids in your <strong>Results</strong> tab.").html_safe
      end
    else
      flash[:warning] = "You have no quotes to decide on."
    end 
    redirect_to :back
  end

  def relist
    show
    unless @line_items.without_bids.blank?
      @line_items.without_bids.update_all(:status => 'Relisted')
      @entry.update_attributes(:buyer_status => 'Relisted', :bid_until => Date.today + 1.week, :chargeable_expiry => nil, :expired => nil)
      flash[:notice] = "Entry was re-listed. Please check your 'Online' tab."
    else
      flash[:error] = "Sorry, there are no items to relist."
    end
    redirect_to :back
    for friend in @entry.user.company.friends
      unless friend.users.nil?
        for seller in friend.users
          EntryMailer.delay.online_entry_alert(seller, @entry)
        end
      end
    end
  end

  def reactivate
    show
    if @entry.update_attributes(:buyer_status => 'For-Decision', :chargeable_expiry => nil, :expired => nil)
      @line_items.each do |line_item|
        unless line_item.order_item
          line_item.update_attribute(:status, 'For-Decision') 
          line_item.bids.update_all(:status => 'For-Decision', :fee => nil, :declined => nil, :expired => nil)
        end
      end
    end
    flash[:notice] = "Entry was reactivated. Please check your 'Results' tab."
    redirect_to :back
  end

  private ##

    def start_entry
      @search = CarPart.name_like_all(params[:name].to_s.split).ascend_by_name
      @car_parts, @car_parts_count = @search.paginate(:page => params[:page], :per_page => 12, :order => 'name ASC'), @search.count
      @car_origins = CarOrigin.includes(:car_brands) # eager loading to make query faster
    end

end
