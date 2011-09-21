class BidsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_filter :check_admin_role, :only => [:index, :edit, :update]
  respond_to :html, :js
  
  def index
    @search = LineItem.with_bids.search(params[:search])
    @line_items = @search.desc.inclusions2.paginate :page => params[:page], :per_page => 20 
    render 'bids/index' 
  end

  def create
    @entry = Entry.find(params[:entry_id])
    @line_items = Array.new
    @new_bids = Array.new
    @existing_bids = Array.new
    @submitted_bids = params[:bids]
    @submitted_bids.each do |line_item, bidtypes|
      bidtypes.reject! { |k, v| v.blank? }
      bidtypes.each do |bid|
        unless bid[1].to_f < 1
          @company = current_user.company
          @line_item = LineItem.find(line_item)
          @existing_bid = Bid.find_by_user_id_and_line_item_id_and_bid_type(@company.users, line_item, bid[0])
          if @existing_bid.nil? 
            #             @new_bid = current_user.bids.build
            # @new_bid.entry_id = @entry.id
            # @new_bid.line_item_id = line_item
            # @new_bid.amount = bid[1]
            # @new_bid.quantity = @line_item.quantity
            # @new_bid.total = bid[1].to_f * @line_item.quantity.to_i
            #             @new_bid.bid_type = bid[0]
            #             @new_bid.car_brand_id = @entry.car_brand_id
            #             @new_bid.bid_speed = @new_bid.compute_bid_speed
            #             @new_bids << @new_bid unless @new_bid.amount < 1

            @new_bid = Bid.populate(current_user, @entry, @line_item, bid[1], bid[0])
            @new_bids << @new_bid unless @new_bid.amount < 1
          else
            if @existing_bid.user != current_user
              @existing_bid.update_attributes!(:user_id => current_user.id, :amount => bid[1], :total => bid[1].to_f * @line_item.quantity.to_i, :status => 'Updated')
            else
              @existing_bid.update_attributes!(:amount => bid[1], :total => bid[1].to_f * @line_item.quantity.to_i, :status => 'Updated')
            end
            @existing_bids << @existing_bid unless @existing_bid.amount < 1
          end
          @line_items << @line_item 
        end
      end
    end

    if @new_bids.compact.length > 0 && @new_bids.all?(&:valid?)
      @new_bids.each(&:save!)
      BidMailer.delay.bid_alert(@new_bids, @entry) 
      BidMailer.delay.bid_alert_to_admin(@new_bids, @entry, current_user)
      flash[:notice] = "Bid/s submitted. Thank you!"
    end
    if @existing_bids.compact.length > 0
      BidMailer.delay.bid_alert_to_admin(@existing_bids, @entry, current_user, 1)
    end
    respond_to do |format|
      format.html { redirect_to :back }
      format.js 
    end      
  end

  def edit
    session['referer'] = request.env["HTTP_REFERER"]
    @bid = Bid.find(params[:id])
  end
  
  def update
    @bid = Bid.find(params[:id])
    @bid.total = (params[:bid][:amount].to_f * params[:bid][:quantity].to_i)
    if @bid.update_attributes(params[:bid])
      redirect_to session['referer'], :notice => 'Bid successfully updated.'
      session['referer'] = nil
    else
      render 'edit'
    end 
  end

  def accept
    # raise params.to_yaml
    @body = 'accept-order'
    unless params[:bids].blank?
      case params[:commit]
      when 'Accept Selected'
        @bids = Bid.find(params[:bids].collect { |item, id| id.values })
        @bid_users = @bids.collect(&:user_id).uniq
        @entry = Entry.find(params[:entry_id])
        order_count = @bid_users.count
        @order = current_user.orders.build
      when 'Decline Selected'
        decline
      end
    else
      flash[:error] = ("Ooops! Choose one of the <strong>Low Bids</strong> first before you accept or decline.").html_safe
      redirect_to :back
    end
  end

  def decline
    @line_items = LineItem.find(params[:bids].keys)
    @bids = Bid.find(params[:bids].collect { |item, id| id.values })
    @entry = Entry.find(params[:entry_id])

    if @line_items.each { |item| item.update_attribute(:status, "Declined") }
      @bids.each do |bid|
        bid.decline_process
      end
      @entry.update_status unless @entry.buyer_status == 'Relisted'
      flash[:warning] = ("Winning bid was declined.  A minimal Transaction Fee worth 
         will be charged 
        to compensate the winning supplier.<br>
        Thank you.").html_safe
    else
      flash[:error] = "Something went wrong. Please try again."
    end
    redirect_to @entry
  end
end
