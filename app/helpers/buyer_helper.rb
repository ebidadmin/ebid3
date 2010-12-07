module BuyerHelper

  # helper for computing buyer fees
  def display_decline_date(entry)
    if entry.expired
      entry.expired.strftime('%b %d')
    else
      entry.updated.strftime('%b %d')
    end
  end

  
end
