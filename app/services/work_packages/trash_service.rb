# frozen_string_literal: true

class WorkPackages::TrashService < WorkPackages::DeleteService
  private

  def default_contract_class
    WorkPackages::TrashContract
  end

  def persist(service_result)
    WorkPackage.transaction do
      trash_work_packages(service_result)
    end

    service_result
  rescue ActiveRecord::ActiveRecordError => e
    service_result.success = false
    service_result.errors.add(:base, e.message)
    service_result
  end

  def trash_work_packages(service_result)
    detach_descendants!(service_result)
    trashable = [model] + deleted_descendants
    mark_as_trashed(trashable, service_result)
    delete_associated_notifications_for(trashable)
    audit("moved_to_trash", trashable)
  end

  def detach_descendants!(service_result)
    detachment_result = detach(unlinked_descendants)
    return if detachment_result.success?

    service_result.merge!(detachment_result)
    raise ActiveRecord::Rollback
  end

  def mark_as_trashed(work_packages, service_result)
    attributes = { deleted_at: Time.current, deleted_by: user, deletion_group: SecureRandom.uuid }

    work_packages.each do |work_package|
      work_package.assign_attributes(attributes)
      work_package.save!(validate: false)
      service_result.add_dependent!(ServiceResult.success(result: work_package)) unless work_package == model
    end
  end

  def delete_associated_notifications_for(work_packages)
    Notification
      .where(resource_type: :WorkPackage, resource_id: work_packages.map(&:id))
      .delete_all
  end

  def audit(action, work_packages)
    Rails.logger.info(
      event: "work_package_trash",
      action:,
      user_id: user.id,
      work_package_ids: work_packages.map(&:id),
      deletion_group: work_packages.first.deletion_group
    )
  end
end
