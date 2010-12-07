class CreateRanks < ActiveRecord::Migration
  def self.up
    create_table :ranks do |t|
      t.string :name
      t.timestamps
    end
    # Rank.create(:name => "Proprietor")
    # Rank.create(:name => "Parts Specialist")
    # Rank.create(:name => "President")
    # Rank.create(:name => "Senior Vice President")
    # Rank.create(:name => "First Vice President")
    # Rank.create(:name => "Vice President")
    # Rank.create(:name => "Senior Manager")
    # Rank.create(:name => "Claims Manager")
    # Rank.create(:name => "Claims Processor")
    # Rank.create(:name => "Claims Assistant")
    # Rank.create(:name => "Claims Evaluator")
    # Rank.create(:name => "Purchaser")
  end

  def self.down
    drop_table :ranks
  end
end
