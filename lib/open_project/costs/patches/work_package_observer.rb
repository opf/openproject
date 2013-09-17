require_dependency 'work_package'

class CostsWorkPackageObserver < ActiveRecord::Observer
  unloadable
  observe :work_package

  def after_update(work_package)
    if work_package.project_id_changed?
      # TODO: This only works with the global cost_rates
      CostEntry.update_all({:project_id => work_package.project_id}, {:work_package_id => work_package.id})
    end
  end

  def before_update(work_package)
    # FIXME: remove this method once controller_work_packages_move_before_save is in 0.9-stable
    if work_package.project_id_changed? && work_package.cost_object_id && !work_package.project.cost_object_ids.include?(work_package.cost_object_id)
     work_package.cost_object = nil
    end
    # true
  end
end
