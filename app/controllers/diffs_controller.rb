class DiffsController < ApplicationController
  before_filter :check_buyer_role
  respond_to :html, :js

  def index
    if current_user.has_role?('admin')
      @search = Entry.bids_count_gt(0).by_this_company(params[:buyer]).search(params[:search])
      @buyers = Company.where(:primary_role => 2).collect { |buyer| [buyer.name, diffs_path(:buyer => buyer)] }
      @buyers.push(['All', diffs_path(:buyer => nil)]) unless @buyers.blank?
      @buyers_path = diffs_path(:buyer => params[:buyer])
    else
      @search = Entry.bids_count_gt(0).by_this_company(current_user.company).desc.search(params[:search])
    end
    @entries = @search.inclusions.paginate :page => params[:page], :per_page => 5
  end

  def show
    @entry = Entry.find(params[:id], :include => ([:line_items => [:car_part, :bids]]))
  end
  
  def create
    # raise params.to_yaml
    @company = params[:canvass_company_id].to_i 
    unless @company.nil?
      @entry = Entry.find(params[:entry_id])
      @line_items = Array.new
      @new_diffs = Array.new
      @submitted_diffs = params[:diffs]
      @submitted_diffs.each do |line_item, difftypes|
        difftypes.reject! { |k, v| v.blank? }
        difftypes.each do |diff|
          unless diff[1].to_f < 1
            @line_item = LineItem.find(line_item)
            @existing_diff = Diff.find_by_line_item_id_and_bid_type(line_item, diff[0])
            if @existing_diff.nil? 
              @new_diff = Diff.populate(@entry, @line_item, diff[0], diff[1].to_f, @company) unless diff[1].to_f < 1
              @new_diffs << @new_diff 
            else
              new_total = diff[1].to_f * @line_item.quantity.to_i
              @existing_diff.update_attributes!(:canvass_amount => diff[1], :canvass_total => new_total, :diff => (@existing_diff.total - new_total if @existing_diff.total), :canvass_company_id => params[:canvass_company_id])
            end
            @line_items << @line_item
          end
        end
      end
    end

    if @new_diffs.compact.length > 0 #&& @new_diffs.all?(&:valid?)
      # @new_diffs.each(&:save!)
      flash[:notice] = "Diff/s submitted. Thank you!"
    end
    respond_to do |format|
      format.html { redirect_to :back }
      format.js 
    end      
  end

  def summary
    @entries = Entry.by_this_company(2).where('entries.created_at >= ?', Time.now.beginning_of_year) # @entries = Entry.where(:company_id => current_user.company, :created_at => ('2010-12-01'..'2011-02-01'))
    @line_items = LineItem.where(:entry_id => @entries) # @line_items = @entries.sum(:line_items_count)
    @with_bids = @line_items.with_bids # @without_bids = @line_items.without_bids.count
    @with_diffs = Diff.where(:buyer_company_id => 2)
    
    @sample = @with_diffs.collect(&:entry_id).uniq
    @sample_parts = LineItem.where(:entry_id => @sample) #@with_diffs.collect(&:line_item_id).uniq
    @sample_parts_pct = (@sample_parts.count.to_f/@line_items.count.to_f) * 100
    
    @with_ebid_and_manual = @with_diffs.diff_not_null
    @savings_rate = (@with_ebid_and_manual.sum(:diff).abs.to_f/@with_ebid_and_manual.sum(:canvass_total).to_f) * 100
    @ebid_lower = @with_diffs.where('diff < ?', 0)
    @ebid_higher = @with_diffs.where('diff > ?', 0)
    @same = @with_diffs.where('diff = ?', 0)
    
    @with_ebid_no_manual =  @sample_parts.with_bids - LineItem.where(:id => @with_diffs.collect(&:line_item_id).uniq) #sample - sample_w_diffs
    @projected_savings = @with_ebid_no_manual.sum(&:compute_lowest_bids) / (1 + @savings_rate)
    @no_ebid_manual_only = @with_diffs.where(:seller_id => nil) - @with_diffs.where(:line_item_id => @sample_parts.with_bids) #@sample_parts.without_bids #@with_diffs.diff_null
    @no_submission = @sample_parts.count -  @with_ebid_and_manual.count - @with_ebid_no_manual.count - @no_ebid_manual_only.count  #@line_items.count - @with_bids.count - @no_ebid_manual_only.count

    @total_effect = @ebid_lower.sum(:diff).abs + @ebid_higher.sum(:diff) + @same.sum(:total) + @projected_savings
    @decline_fees = @search = Fee.where(:entry_id => @sample).declined
    @orders = Order.where(:company_id => 2).total_delivered.where('orders.created_at >= ?', Time.now.beginning_of_year)
    @ordered_parts = @orders.sum(:order_items_count)
    @orders_in_survey = @orders.where(:entry_id => @sample)
    render :layout => 'print'
  end
end
