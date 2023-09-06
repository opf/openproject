class AddPaybackLikelihoodToWorkPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :work_packages, :payback_likelihood, :float
  end
end
