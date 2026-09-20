# frozen_string_literal: true

class WorkPackages::PurgeService < BaseServices::Delete
  private

  def default_contract_class
    WorkPackages::PurgeContract
  end

  def persist(service_result)
    records = group_members
    audit(records)

    WorkPackage.transaction do
      records_in_destroy_order(records).each do |work_package|
        next if work_package.destroyed?

        success = work_package.destroy
        service_result.add_dependent!(ServiceResult.new(success:, result: work_package)) unless work_package == model
        unless success
          service_result.success = false
          service_result.errors.merge!(work_package.errors)
          raise ActiveRecord::Rollback
        end
      end
    end

    service_result
  rescue ActiveRecord::ActiveRecordError => e
    service_result.success = false
    service_result.errors.add(:base, e.message)
    service_result
  end

  def group_members
    scope = WorkPackage.with_trashed
    scope = scope.where(deletion_group: model.deletion_group) if model.deletion_group.present?
    scope = scope.where(id: model.id) if model.deletion_group.blank?
    scope.order(:id).to_a
  end

  def records_in_destroy_order(records)
    depths = WorkPackageHierarchy
      .where(descendant_id: records.map(&:id))
      .group(:descendant_id)
      .maximum(:generations)

    records.sort_by { |work_package| -depths.fetch(work_package.id, 0) }
  end

  def audit(work_packages)
    Rails.logger.info(
      event: "work_package_trash",
      action: "permanently_deleted",
      user_id: user.id,
      work_package_ids: work_packages.map(&:id),
      deletion_group: model.deletion_group
    )
  end
end
