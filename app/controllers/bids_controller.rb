class BidsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  respond_to :html, :js
  
  def index
  end

  def create
    # raise params.to_yaml
    @entry = Entry.find(params[:entry_id])
    @line_items = @entry.line_items
    
    @new_bids = Array.new
    @submitted_bids = params[:bids]
    @submitted_bids.each do |line_item, bidtypes|
      @line_item = LineItem.find(line_item)

      bidtypes.reject! { |k, v| v.blank? }
      bidtypes.each do |bid|
        unless bid[1].to_f < 1
          @existing_bid = current_user.bids.find_by_line_item_id_and_bid_type(line_item, bid[0])
          if @existing_bid.nil? 
            @new_bid = current_user.bids.build
        		@new_bid.entry_id = @entry.id
        		@new_bid.line_item_id = line_item
        		@new_bid.amount = bid[1]
        		@new_bid.quantity = @line_item.quantity
        		@new_bid.total = bid[1].to_f * @line_item.quantity.to_i
            @new_bid.bid_type = bid[0]
            @new_bids << @new_bid unless @new_bid.amount < 1
          else
            @existing_bid.update_attributes!(:amount => bid[1], :total => bid[1].to_f * @line_item.quantity.to_i, :status => 'Updated')
          end
        end
      end
    end

    if @new_bids.compact.length > 0 && @new_bids.all?(&:valid?)
      @new_bids.each(&:save!)
      @powerbuyers = @entry.user.company.users.where(:id => Role.find_by_name('powerbuyer').users).collect { |u| "#{u.profile.full_name} <#{u.email}>" }
      BidMailer.delay.bid_alert(@new_bids, @entry, @powerbuyers) 
      BidMailer.delay.bid_alert_to_admin(@new_bids, @entry, current_user)
      flash[:notice] = "Bid/s submitted. Thank you!"
    end
    # redirect_to :back # respond_with(@new_bids, :location => :back)
  end

  def show
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
        <strong>#{ number_to_currency @bids.collect(&:fee).sum, :unit => 'P '}</strong> will be charged 
        to compensate the winning supplier.<br>
        Thank you.").html_safe
    else
      flash[:error] = "Something went wrong. Please try again."
    end
    redirect_to @entry
  end
end
