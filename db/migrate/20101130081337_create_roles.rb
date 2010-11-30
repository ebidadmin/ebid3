class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string :name
    end

    Role.create(:name => 'admin')
    Role.create(:name => 'powerbuyer')
    Role.create(:name => 'buyer')
    Role.create(:name => 'powerseller')
    Role.create(:name => 'seller')

    # generate the join table
    create_table "roles_users", :id => false do |t|
      t.integer "role_id", "user_id"
    end

    add_index "roles_users", "role_id"
    add_index "roles_users", "user_id"

    chris = User.find_by_username('chrism')
    efren = User.find_by_username('efren')
    role = Role.find_by_name('admin')
    chris.roles << role
    efren.roles << role
  end

  def self.down
    drop_table :roles
  end
end
