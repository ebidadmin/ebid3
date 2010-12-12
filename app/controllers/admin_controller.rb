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
      @search = Entry.car_brand_id_eq(brand).descend_by_id.search(params[:search])
    else
      @search = Entry.descend_by_id.search(params[:search])
    end
    @brand_links = Entry.all.collect(&:car_brand).uniq  #.sort! { |a,b| a.name.downcase <=> b.name.downcase }
    @entries = @search.all.paginate(:page => params[:page], :per_page => 10)
  end

end
