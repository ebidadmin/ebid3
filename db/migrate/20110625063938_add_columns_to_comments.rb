class AddColumnsToComments < ActiveRecord::Migration
  def self.up
    rename_column :comments, :user_id, :sender_id 
    add_column :comments, :sender_company_id, :integer
    add_column :comments, :receiver_id, :integer
    add_column :comments, :receiver_company_id, :integer
    add_column :comments, :order_id, :integer
    for comment in Comment.all
      if comment.user_type == 'seller' || comment.user_type == 'admin'
        comment.sender_company_id = comment.sender.company.id
        comment.receiver_id = comment.entry.user.id
        comment.receiver_company_id = Company.find(comment.receiver.company).id
      else
        comment.sender_company_id = comment.sender.company.id
      end
      comment.save!
    end
  end

  def self.down
    remove_column :comments, :order_id
    remove_column :comments, :receiver_company_id
    remove_column :comments, :receiver_id
    remove_column :comments, :sender_company_id
    rename_column :comments, :sender_id, :user_id
  end
end