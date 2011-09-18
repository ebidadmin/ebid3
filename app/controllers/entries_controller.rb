class EntriesController < ApplicationController
  before_filter :initialize_cart, :only => [:select_parts, :show, :edit]
  before_filter :check_buyer_role

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
    @entry = Entry.find(params[:id], :include => ([:line_items => [:car_part, :bids]]))
    if current_user.has_role?('admin')
      @priv_messages = @entry.messages.closed
    else
      @priv_messages = @entry.messages.closed.restricted(current_user.company)
    end
    @pub_messages = @entry.messages.open
    if @entry.buyer_status == 'Relisted'
      @line_items = @entry.line_items.order('status DESC').includes(:car_part, :bids)
    else
      @line_items = @entry.line_items.includes(:car_part, :bids)
    end
  end

  def print
    @entry = Entry.find(params[:id], :include => ([:line_items => [:car_part, :bids]]))
    if current_user.has_role?('admin')
      @priv_messages = @entry.messages.closed
    else
      @priv_messages = @entry.messages.closed.restricted(current_user.company)
    end
    @pub_messages = @entry.messages.open
    render :layout => 'print'
  end
  
  def duplicates
    @search = Entry.search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'
  end
  
  def new
    @entry = current_user.entries.build
    @entry.date_of_loss = Date.today
    @entry.term_id = 4
    @car_origins = CarOrigin.includes(:car_brands) # eager loading to make query faster
  end
  
  def create
    @search = Entry.search(params[:entry][:plate_no])
    if @search.present?
      @entries = @search.paginate(:page => params[:page], :per_page => 10)
      render 'entries/index'
    else
      @entry = current_user.entries.build(params[:entry])
      if current_user.company.entries << @entry
        redirect_to edit_entry_path(@entry), :notice => "Saved #{@entry.vehicle}. Next step is to choose parts."
      else
        @car_origins = CarOrigin.includes(:car_brands) # eager loading to make query faster
        flash[:error] = "Looks like you forgot to complete the required vehicle info.  Try again!"
        render 'new'
      end
    end
  end
  
  def attach_photos
    @entry = Entry.find(params[:id])
    if @entry.photos.first.blank?
      2.times {@entry.photos.build}
    end
  end
  
  def edit
    session['referer'] = request.env["HTTP_REFERER"]
    if current_user.has_role?('admin') || current_user.has_role?('powerbuyer')
      @entry = Entry.find(params[:id])
    else
      @entry = current_user.entries.find(params[:id])
    end
    @line_items = @entry.line_items.includes(:car_part, :bids)
    if @entry.photos.first.blank?
      2.times {@entry.photos.build}
    end
  end
  
  def edit_vehicle
    @entry = Entry.find(params[:id])
    @car_origins = CarOrigin.includes(:car_brands) # eager loading to make query faster
  end
  
  def update
    if current_user.has_role?('admin') || current_user.has_role?('powerbuyer')
      @entry = Entry.find(params[:id])
    else
      @entry = current_user.entries.find(params[:id])
    end
    
    if @entry.update_attributes(params[:entry])
      redirect_to @entry, :notice => "Updated #{@entry.vehicle}."
    else
      @car_origins = CarOrigin.includes(:car_brands) # eager loading to make query faster
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
    @entry = Entry.find(params[:id], :include => ([:line_items => [:car_part, :bids]]))
    @line_items = @entry.line_items
    
    if @line_items.fresh.present? && @entry.photos.present?
      if @entry.update_attributes(:buyer_status => "Online", :online => Time.now, :bid_until => Time.now + 1.week)
        @entry.update_associated_status("Online")
        flash[:notice] = ("Your entry is <strong>now online</strong>. Thanks!").html_safe
      end
      redirect_to :back
      for friend in @entry.user.company.friends
        unless friend.users.nil?
          for seller in friend.users
            EntryMailer.delay.online_entry_alert(seller, @entry) if seller.opt_in == true
          end
        end
      end
    else
      flash[:error] = "Oops ... your entry is not yet complete. Please check the photos and parts before you proceed."
      redirect_to :back
    end
    # @powerbuyers = @entry.user.company.users.where(:id => Role.find_by_name('powerbuyer').users).collect { |u| "#{u.profile.full_name} <#{u.email}>" }
    # @friends = @entry.user.company.friends.map {|f| f.users.collect{ |u| "#{u.profile.full_name} <#{u.email}>" }}
    # EntryMailer.delay.online_entry_alert(@friends, @entry)
  end

  def reveal_bids 
    @entry = Entry.find(params[:id], :include => ([:line_items => [:car_part, :bids]]))
    unless @entry.bids.blank?
      if @entry.update_attribute(:buyer_status, "For-Decision")
        @entry.update_associated_status("For-Decision")
        flash[:notice] = ("Great! You can now view the winning bids in your <strong>Results</strong> tab.").html_safe
      end
    else
      flash[:warning] = "You have no quotes to decide on."
    end 
    redirect_to @entry #:back
  end

  def relist
    @entry = Entry.find(params[:id], :include => ([:line_items => [:car_part, :bids]]))
    @line_items = @entry.line_items
    unless @line_items.without_bids.blank?
      if @line_items.relistable.present?
        @line_items.relistable.update_all(:status => 'Relisted', :relisted => Time.now)
        @entry.update_attributes(:buyer_status => 'Relisted', :bid_until => Time.now + 1.week, :relisted => Time.now, :relist_count => @entry.relist_count += 1, :chargeable_expiry => nil, :expired => nil)
        flash[:notice] = "Entry was re-listed. Please check your <strong>Online</strong> tab.".html_safe
      end
      if @line_items.fresh.present?
        @line_items.fresh.update_all(:status => 'Online')
        @entry.update_attributes(:buyer_status => 'Additional', :bid_until => Time.now + 1.week, :relisted => Time.now, :relist_count => @entry.relist_count += 1, :chargeable_expiry => nil, :expired => nil)
        flash[:notice] = "New parts are now online. Please check your <strong>Online</strong> tab.".html_safe
      end
      redirect_to @entry
    else
      flash[:error] = "Sorry, there are no items to relist."
      redirect_to :back
    end
    # for friend in @entry.user.company.friends
    #   unless friend.users.nil?
    #     for seller in friend.users
    #       EntryMailer.delay.online_entry_alert(seller, @entry)
    #     end
    #   end
    # end
  end

  def reactivate
    @entry = Entry.find(params[:id], :include => ([:line_items => [:car_part, :bids]]))
    if @entry.update_attributes(:buyer_status => 'For-Decision', :chargeable_expiry => nil, :expired => nil)
      @entry.line_items.each do |line_item|
        unless line_item.order_item
          line_item.update_attribute(:status, 'For-Decision') 
          line_item.bids.update_all(:status => 'For-Decision', :declined => nil, :expired => nil)
          line_item.fee.destroy if line_item.fee #TODO fee should be updated temporarily, not deleted
        end
      end
    end
    flash[:info] = "Entry was reactivated. Please check your 'Results' tab."
    redirect_to :back
  end

  private ##

    def search_parts
      @search = CarPart.name_like_all(params[:name].to_s.split).order(:id)
      @car_parts, @car_parts_count = @search.paginate(:page => params[:page], :per_page => 96), @search.count
    end

end
