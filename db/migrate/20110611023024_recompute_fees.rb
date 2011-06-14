class RecomputeFees < ActiveRecord::Migration
  def self.up
    add_column :companies, :trial_start, :date
    add_column :companies, :trial_end, :date
    add_column :companies, :metering_date, :date
    add_column :companies, :perf_ratio, :decimal, :precision => 5, :scale => 2
    
    add_column :fees, :bid_speed, :integer
    add_column :fees, :fee_rate, :decimal, :precision => 5, :scale => 3
    add_column :fees, :order_paid, :date
    
    for company in Company.all
      if company.primary_role == 2 # buyer
        unless company.entries.blank?
        line_items = LineItem.with_bids.where(:entry_id => company.entries).count
        parts_ordered = company.orders.map{|order| order.order_items.count}.sum
        company.perf_ratio = (BigDecimal("#{parts_ordered}")/BigDecimal("#{line_items}")).to_f * 100
        end
      elsif company.primary_role == 3 # seller
        line_items = LineItem.metered.count
        parts_bided = company.users.map{|user| user.bids.metered.collect(&:line_item_id).uniq.count}.sum
        company.perf_ratio = (BigDecimal("#{parts_bided}")/BigDecimal("#{line_items}")).to_f * 100
      elsif company.id == 1
        company.perf_ratio = 100
      end
      company.metering_date = '2011-04-16'
      company.save!
    end
    
    for fee in Fee.all
      unless fee.bid.blank?
        fee.bid_speed = fee.bid.bid_speed 
        if fee.fee_type == 'Ordered' # Market Fees
          ratio = fee.seller_company.perf_ratio
          if ratio < 70
            fee.fee_rate = 3.5 - fee.seller_discount
          elsif ratio < 80           
            fee.fee_rate = 3.0 - fee.seller_discount
          elsif ratio >= 80         
            fee.fee_rate = 2.0 - fee.seller_discount
          end
          fee.order_paid = fee.order.paid
        else # Decline Fees
          ratio = fee.buyer_company.perf_ratio
          if ratio < 10
            fee.fee_rate = 0.5 - fee.buyer_discount(0.5)
          elsif ratio < 30
            fee.fee_rate = 0.375 - fee.buyer_discount(0.375)
          elsif ratio < 50
            fee.fee_rate = 0.25 - fee.buyer_discount(0.25)
          elsif ratio >= 50
            fee.fee_rate = 0
          end
        end
        fee.fee = fee.bid_total * (fee.fee_rate/100)
        fee.split_amount = fee.fee/2
        fee.save!
      end
    end
  end

  def self.down
    remove_column :companies, :perf_ratio
    remove_column :companies, :trial_end
    remove_column :companies, :trial_start
    remove_column :companies, :metering_date
    remove_column :fees, :fee_rate
    remove_column :fees, :bid_speed
    remove_column :fees, :order_paid
  end
end