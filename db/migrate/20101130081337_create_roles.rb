class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string :name
    end
    
    # Role.create(:name => 'admin')
    # Role.create(:name => 'buyer')
    # Role.create(:name => 'seller')
    # Role.create(:name => 'powerbuyer')
    # Role.create(:name => 'powerseller')
    
    # generate the join table
    create_table "roles_users", :id => false do |t|
      t.integer "role_id", "user_id"
    end
    
    add_index "roles_users", "role_id"
    add_index "roles_users", "user_id"

    # chris = User.where('username = ?', 'chrism')
    # role = Role.where('name = ?','admin')
    # chris.roles << role
    # efren = User.where('username = ?', 'efren')
    # role2 = Role.where('name = ?','buyer')
    # efren.roles << role2
  end

  def self.down
    drop_table :roles_users
    drop_table :roles
  end
end
