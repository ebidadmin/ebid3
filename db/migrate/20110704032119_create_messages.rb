class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.integer :user_id
      t.string :user_type
      t.integer :user_company_id
      t.integer :receiver_id
      t.integer :receiver_company_id
      t.integer :entry_id
      t.integer :order_id
      t.text :message
      t.boolean :open, :default => false # pertains to public message; 'public' is a reserved term in rails
      t.string :ancestry
      t.timestamps
    end
    
    add_index :messages, :user_id
    add_index :messages, :user_company_id
    add_index :messages, :receiver_id
    add_index :messages, :receiver_company_id
    add_index :messages, :entry_id
    add_index :messages, :order_id
    add_index :messages, :ancestry
    
    for c in Comment.all
      m = Message.new
      m.user_type = c.user_type
      if c.user_id.blank? && m.user_type == 'seller'
        m.user_id = 31
        m.user_company_id = 20
      elsif c.user_id.blank? && m.user_type == 'buyer'
        m.user_id = 40
        m.user_company_id = 2
      elsif c.user_id.blank? && m.user_type == 'admin'
        m.user_id = 1
        m.user_company_id = 1
      else
        m.user_id = c.user_id
        m.user_company_id = c.user.company.id
      end
      m.entry_id = c.entry_id
      m.message = c.comment
      m.created_at = c.created_at
      m.updated_at = c.updated_at
      if m.user_type == 'seller' || m.user_type == 'admin'
        m.receiver_id = c.entry.user_id
        m.receiver_company_id = c.entry.company_id
      elsif m.user_type == 'buyer'
        m.receiver_id = 1
        m.receiver_company_id = 1
      end
      m.save!
    end
  end

  def self.down
    remove_index :messages, :ancestry
    remove_index :messages, :order_id
    remove_index :messages, :entry_id
    remove_index :messages, :receiver_company_id
    remove_index :messages, :receiver_id
    remove_index :messages, :user_company_id
    remove_index :messages, :user_id
    drop_table :messages
  end
end