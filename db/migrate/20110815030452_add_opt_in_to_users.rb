class AddOptInToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :rules, :datetime
    add_column :users, :opt_in, :boolean, :default => true
    add_index :users, :opt_in
  end

  def self.down
    remove_index :users, :opt_in
    remove_column :users, :opt_in
    remove_column :users, :rules
  end
end