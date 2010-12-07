class DeviseCreateUsers < ActiveRecord::Migration
  def self.up
    create_table(:users) do |t|
      t.string :username, :limit => 20
      t.database_authenticatable :null => false
      t.recoverable
      t.rememberable
      t.trackable
      t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      t.timestamps
      t.boolean :enabled, :default => true, :null => false                      
      t.integer :entries_count, :null => false, :default => 0                                      
      t.integer :bids_count, :null => false, :default => 0                                      
   end
    
    add_index :users, :username
    add_index :users, :email,                :unique => true
    add_index :users, :reset_password_token, :unique => true
    add_index :users, :unlock_token,         :unique => true
    User.create!(:username => 'chrism', 
                :email => 'cymarquez@mac.com', 
                :password => 'chrism',
                :password_confirmation => 'chrism')
    User.create!(:username => 'efren', 
                :email => 'efren@ebid.com.ph', 
                :password => 'efren',
                :password_confirmation => 'efren')
   end

  def self.down
    drop_table :users
  end
end
