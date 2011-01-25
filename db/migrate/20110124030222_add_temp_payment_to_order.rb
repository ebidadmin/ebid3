class AddTempPaymentToOrder < ActiveRecord::Migration
  def self.up
    add_column :orders, :paid_temp, :date
  end

  def self.down
    remove_column :orders, :paid_temp
  end
end