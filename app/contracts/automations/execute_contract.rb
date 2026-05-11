# frozen_string_literal: true

module Automations
  class ExecuteContract < BaseContract
    property :lock_version
    property :work_package_id

    validates :work_package_id, presence: true
    validate :work_package_visible
    validate :automation_conditions_fulfilled

    private

    def work_package_visible
      return unless model.work_package_id

      errors.add(:work_package_id, :does_not_exist) unless WorkPackage.visible(user).where(id: model.work_package_id).exists?
    end

    def automation_conditions_fulfilled
      return unless model.work_package_id
      return unless options[:automation]

      work_package = WorkPackage.visible(user).find_by(id: model.work_package_id)
      return unless work_package

      errors.add(:base, :error_unauthorized) unless options[:automation].conditions_fulfilled?(work_package, user)
    end
  end
end
