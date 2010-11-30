# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101130094324) do

  create_table "car_brands", :force => true do |t|
    t.integer  "car_origin_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "car_brands", ["car_origin_id"], :name => "index_car_brands_on_car_origin_id"

  create_table "car_models", :force => true do |t|
    t.integer  "car_brand_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "car_models", ["car_brand_id"], :name => "index_car_models_on_car_brand_id"

  create_table "car_origins", :force => true do |t|
    t.string "name"
  end

  create_table "car_parts", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "car_variants", :force => true do |t|
    t.integer  "car_brand_id"
    t.integer  "car_model_id"
    t.string   "name"
    t.string   "start_year"
    t.string   "end_year"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "car_variants", ["car_brand_id"], :name => "index_car_variants_on_car_brand_id"
  add_index "car_variants", ["car_model_id"], :name => "index_car_variants_on_car_model_id"

  create_table "cart_items", :force => true do |t|
    t.integer  "cart_id"
    t.integer  "car_part_id"
    t.integer  "quantity"
    t.string   "part_no"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cart_items", ["car_part_id"], :name => "index_cart_items_on_car_part_id"
  add_index "cart_items", ["cart_id"], :name => "index_cart_items_on_cart_id"

  create_table "carts", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cities", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "companies", :force => true do |t|
    t.string   "name"
    t.string   "address1"
    t.string   "address2"
    t.string   "zip_code"
    t.integer  "city_id"
    t.string   "approver"
    t.string   "approver_position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "primary_role"
  end

  create_table "friendships", :force => true do |t|
    t.integer  "company_id"
    t.integer  "friend_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "friendships", ["company_id"], :name => "index_friendships_on_company_id"
  add_index "friendships", ["friend_id"], :name => "index_friendships_on_friend_id"

  create_table "profiles", :force => true do |t|
    t.integer  "user_id"
    t.integer  "company_id"
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "rank_id"
    t.string   "phone"
    t.string   "fax"
    t.date     "birthdate"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "profiles", ["company_id"], :name => "index_profiles_on_company_id"
  add_index "profiles", ["user_id"], :name => "index_profiles_on_user_id"

  create_table "ranks", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string "name"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "terms", :force => true do |t|
    t.integer "name"
  end

  create_table "users", :force => true do |t|
    t.string   "username",             :limit => 20
    t.string   "email",                               :default => "",   :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "",   :null => false
    t.string   "password_salt",                       :default => "",   :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",                     :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "enabled",                             :default => true, :null => false
    t.integer  "entries_count",                       :default => 0,    :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username"

end
