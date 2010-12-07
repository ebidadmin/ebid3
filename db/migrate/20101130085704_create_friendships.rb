class CreateFriendships < ActiveRecord::Migration
  def self.up
    create_table :friendships, :id => false do |t|
      t.integer :company_id
      t.integer :friend_id
      t.timestamps
    end
    add_index :friendships, :company_id
    add_index :friendships, :friend_id
  end

  def self.down
    remove_index :friendships, :friend_id
    remove_index :friendships, :company_id
    drop_table :friendships
  end
end