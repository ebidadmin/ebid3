class DiffsController < ApplicationController
  # before_filter :check_admin_role

  respond_to :html, :js

  def index
    # if current_user.has_role?('admin')
    #   @search = Entry.bids_count_gt(0).desc.search(params[:search])
    #   @buyers = @search.collect(&:buyer_company).uniq.collect { |buyer| [Company.find(buyer).name, diffs_path(:buyer => buyer)] }
    #   @buyers.push(['All', diffs_path(:buyer => nil)]) unless @buyers.blank?
    #   @buyers_path = diffs_path(:buyer => params[:buyer])
    # else
    #   @search = Entry.bids_count_gt(0).where(:company_id => current_user.company).desc.search(params[:search])
    # end
    @search = Entry.bids_count_gt(0).where(:company_id => 23).desc.search(params[:search])
    @entries = @search.inclusions.paginate :page => params[:page], :per_page => 5
  end

  def show
    @entry = Entry.find(params[:id], :include => ([:line_items => [:car_part, :bids]]))
  end
  
  def create
    # raise params.to_yaml
    @entry = Entry.find(params[:entry_id])
    @line_items = @entry.line_items
    
    @new_diffs = Array.new
    @submitted_diffs = params[:diffs]
    @submitted_diffs.each do |line_item, difftypes|
      @line_item = LineItem.find(line_item)

      difftypes.reject! { |k, v| v.blank? }
      difftypes.each do |diff|
        unless diff[1].to_f < 1
          @existing_diff = Diff.find_by_line_item_id_and_bid_type(line_item, diff[0])
          if @existing_diff.nil? 
            @new_diff = Diff.new
        		@new_diff.buyer_company_id = @entry.company_id
        		@new_diff.buyer_id = @entry.user_id
        		@new_diff.entry_id = @entry.id
        		@new_diff.line_item_id = @line_item.id
            @new_diff.bid_type = diff[0]
        		@new_diff.canvass_amount = diff[1].to_f
        		@new_diff.canvass_total = diff[1].to_f * @line_item.quantity.to_i
            @new_diff.canvass_company_id = params[:canvass_company_id].to_i
            # @existing_bid = Bid.find_by_line_item_id_and_bid_type_and_amount(@line_item.id, diff[0], diff[1]) #Bid.find_by_line_item_id_and_bid_type(line_item, diff[0])
            @existing_bid = Bid.where(:line_item_id => line_item, :bid_type => diff[0]).order(:amount).first
        		if @existing_bid.present? 
          		@new_diff.seller_company_id = @existing_bid.user.company.id
          		@new_diff.seller_id = @existing_bid.user_id
          		@new_diff.bid_id = @existing_bid.id 
          		@new_diff.amount = @existing_bid.amount 
          		@new_diff.quantity = @existing_bid.quantity
          		@new_diff.total = @existing_bid.total
          		@new_diff.diff = @new_diff.total - @new_diff.canvass_total
        		end
            @new_diffs << @new_diff unless @new_diff.canvass_amount < 1
          else
            new_total = diff[1].to_f * @line_item.quantity.to_i
            @existing_diff.update_attributes!(:canvass_amount => diff[1], :canvass_total => new_total, :diff => (@existing_diff.total - new_total if @existing_diff.total), :canvass_company_id => params[:canvass_company_id])
          end
        end
      end
      # @line_items = Array.new
      # @line_items << @line_item
    end

    if @new_diffs.compact.length > 0 && @new_diffs.all?(&:valid?)
      @new_diffs.each(&:save!)
      flash[:notice] = "Diff/s submitted. Thank you!"
    end
    respond_to do |format|
      format.html { redirect_to :back }
      format.js 
    end      
  end

  def summary
    @entries = Entry.where(:company_id => current_user.company, :created_at => ('2010-12-01'..'2011-02-01'))
    @line_items = LineItem.where(:entry_id => @entries)
    @with_bids = @line_items.with_bids
    # @without_bids = @line_items.without_bids.count
    @manual_canvass = Diff.scoped
    @with_ebid_and_manual = @manual_canvass.diff_not_null
    @ebid_lower = @manual_canvass.where('diff < ?', 0)
    @ebid_higher = @manual_canvass.where('diff > ?', 0)
    @same = @manual_canvass.where('diff = ?', 0)
    @with_ebid_no_manual = @with_bids - LineItem.where(:id => @manual_canvass.collect(&:line_item_id).uniq)
    @no_ebid_manual_only = @manual_canvass.diff_null
    @no_submission = @line_items.count - @with_bids.count - @no_ebid_manual_only.count
  end
end
