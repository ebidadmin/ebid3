class CreateRemarks < ActiveRecord::Migration
  def self.up
    create_table :remarks do |t|
      t.integer :user_id
      t.integer :entry_id
      t.text :remark

      t.timestamps
    end
  end

  def self.down
    drop_table :remarks
  end
end
