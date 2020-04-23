class AddIssueColumns < ActiveRecord::Migration[6.0]
  def change
    change_table :bcf_issues do |i|
      i.string :stage
      i.integer :index
      i.text :labels, array: true, default: []
    end
  end
end
