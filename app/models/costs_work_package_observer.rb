class CostsWorkPackageObserver < ActiveRecord::Observer
  unloadable
  observe :work_package

  def after_update(work_package)
    if work_package.project_id_changed?
      # TODO: This only works with the global cost_rates
      CostEntry.update_all({:project_id => work_package.project_id}, {:work_package_id => work_package.id})
    end
  end
end
