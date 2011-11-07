class AdminPresenter
  extend ActiveSupport::Memoizable
  
  def initialize(user)
    @user = user
  end
  
  def line_items
    LineItem.scoped
  end
  
  def bids
    Bid.order(:bid_speed)
  end
  
  def uniq_bids
    bids.collect(&:line_item_id).uniq.count
  end
  
  def uniq_bids_m
    bids.metered.collect(&:line_item_id).uniq.count
  end
  
  def uniq_bids_f
    bids.ftm.collect(&:line_item_id).uniq.count
  end
  memoize :line_items, :bids
end