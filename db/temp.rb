  
  add_index :comments, :sender_id
  add_index :comments, :sender_company_id
  add_index :comments, :receiver_id
  add_index :comments, :receiver_company_id
  add_index :comments, :entry_id
  add_index :comments, :order_id
  add_index :fees, :buyer_company_id
  add_index :fees, :buyer_id
  add_index :fees, :seller_company_id
  add_index :fees, :seller_id
  add_index :fees, :bid_id
end

def self.down
  remove_index :comments, :order_id
  remove_index :comments, :entry_id
  remove_index :comments, :receiver_company_id
  remove_index :comments, :receiver_id
  remove_index :comments, :sender_company_id
  remove_index :comments, :sender_id
  remove_index :fees, :bid_id
  remove_index :fees, :seller_id
  remove_index :fees, :seller_company_id
  remove_index :fees, :buyer_id
  remove_index :fees, :buyer_company_id
