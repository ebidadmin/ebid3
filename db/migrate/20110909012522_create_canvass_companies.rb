class CreateCanvassCompanies < ActiveRecord::Migration
  def self.up
    create_table :canvass_companies do |t|
      t.string :name
      t.string :role
    end
    
    # for company in Company.all
    #   canv_comp = CanvassCompany.create(:id => company.id, :name => company.name, :role => company.primary_role)
    # end
  end

  def self.down
    drop_table :canvass_companies
  end
end
