# frozen_string_literal: true

class WorkPackages::RestoreService < BaseServices::Delete
  private

  def default_contract_class
    WorkPackages::RestoreContract
  end

  def persist(service_result)
    deletion_group = model.deletion_group
    restored = WorkPackage.transaction do
      group_members.each do |work_package|
        work_package.assign_attributes(deleted_at: nil, deleted_by: nil, deletion_group: nil)
        work_package.save!(validate: false)
        service_result.add_dependent!(ServiceResult.success(result: work_package)) unless work_package == model
      end

      audit(group_members, deletion_group)
      group_members
    end

    service_result.result = restored.first || model
    service_result
  rescue ActiveRecord::ActiveRecordError => e
    service_result.success = false
    service_result.errors.add(:base, e.message)
    service_result
  end

  def group_members
    @group_members ||= if model.deletion_group.present?
                         WorkPackage.with_trashed.where(deletion_group: model.deletion_group).order(:id).to_a
                       else
                         [model]
                       end
  end

  def audit(work_packages, deletion_group)
    Rails.logger.info(
      event: "work_package_trash",
      action: "restored",
      user_id: user.id,
      work_package_ids: work_packages.map(&:id),
      deletion_group:
    )
  end

  # Restoring is an update, not a physical destroy.
  def destroy(*) = true
end
