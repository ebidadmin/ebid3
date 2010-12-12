class CreateTerms < ActiveRecord::Migration
  def self.up
    create_table :terms do |t|
      t.integer :name
    end
    # Term.create(:name => 0)
    # Term.create(:name => 7)
    # Term.create(:name => 15)
    # Term.create(:name => 30)
    # Term.create(:name => 45)
  end

  def self.down
    drop_table :terms
  end
end
