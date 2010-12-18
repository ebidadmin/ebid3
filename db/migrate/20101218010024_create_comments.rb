class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.integer :user_id
      t.string :user_type
      t.integer :entry_id
      t.text :comment
      t.timestamps
    end
  end

  def self.down
    drop_table :comments
  end
end
