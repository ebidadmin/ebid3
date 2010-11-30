class CreatePhotos < ActiveRecord::Migration
  def self.up
    create_table :photos do |t|
      t.integer :entry_id
      t.string :photo_file_name
      t.string :photo_content_type
      t.integer :photo_file_size
      t.datetime :photo_updated_at
      t.boolean :processing
      t.timestamps
    end
    add_index :photos, :entry_id
  end

  def self.down
    remove_index :photos, :entry_id
    drop_table :photos
  end
end