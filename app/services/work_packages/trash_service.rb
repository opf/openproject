# frozen_string_literal: true

class WorkPackages::TrashService < WorkPackages::DeleteService
  private

  def default_contract_class
    WorkPackages::TrashContract
  end

  def persist(service_result)
    WorkPackage.transaction do
      detachable = unlinked_descendants
      trashable = [model] + deleted_descendants

      detachment_result = detach(detachable)
      unless detachment_result.success?
        service_result.merge!(detachment_result)
        raise ActiveRecord::Rollback
      end

      deletion_group = SecureRandom.uuid
      deleted_at = Time.current

      trashable.each do |work_package|
        work_package.assign_attributes(deleted_at:, deleted_by: user, deletion_group:)
        work_package.save!(validate: false)
        service_result.add_dependent!(ServiceResult.success(result: work_package)) unless work_package == model
      end

      delete_associated_notifications_for(trashable)
      audit("moved_to_trash", trashable)
    end

    service_result
  rescue ActiveRecord::ActiveRecordError => e
    service_result.success = false
    service_result.errors.add(:base, e.message)
    service_result
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
