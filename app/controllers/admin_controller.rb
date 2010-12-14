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
    @buyers = Role.find_by_name('buyer').users
    unless params[:brand].nil?
      brand = CarBrand.find_by_name(params[:brand])
      @search = Entry.where(:car_brand => brand).desc.search(params[:search])
    else
      @search = Entry.search(params[:search])
    end
    @brand_links = Entry.all.collect(&:car_brand).uniq  #.sort! { |a,b| a.name.downcase <=> b.name.downcase }
    @entries = @search.all.paginate(:page => params[:page], :per_page => 10)
  end

  # entries = Entry.online.current.desc
  # @brand_links = entries.collect(&:car_brand).uniq 
  # if params[:brand] == 'all'
  #   @entries = entries.paginate(:page => params[:page], :per_page => 10)
  # else
  #   brand = CarBrand.find_by_name(params[:brand])
  #   @entries = entries.where(:car_brand_id => brand).paginate :page => params[:page], :per_page => 10
  # end

end
