# frozen_string_literal: true

class Automations::UpdateWorkPackageService
  include Shared::BlockService
  include Contracted

  attr_accessor :user,
                :action

  def initialize(action:, user:)
    self.action = action
    self.user = user
    self.contract_class = ::WorkPackages::UpdateContract
  end

  def call(work_package:, &)
    apply_actions(work_package, action.actions)

    result = ::WorkPackages::UpdateService
             .new(user:,
                  model: work_package)
             .call

    block_with_result(result, &)
  end

  private

  def apply_actions(work_package, actions)
    changes_before = work_package.changes.dup
    apply_actions_sorted(work_package, actions)

    success, errors = validate(work_package, user)
    retry_apply_actions(work_package, actions, errors, changes_before) unless success
  end

  def retry_apply_actions(work_package, actions, errors, changes_before)
    new_actions = without_invalid_actions(actions, errors)

    if new_actions.any? && actions.length != new_actions.length
      work_package.restore_attributes(work_package.changes.keys - changes_before.keys)
      apply_actions(work_package, new_actions)
    end
  end

  def without_invalid_actions(actions, errors)
    invalid_keys = errors.attribute_names.map { |k| append_id(k) }
    actions.reject { |a| invalid_keys.include?(append_id(a.key)) }
  end

  def apply_actions_sorted(work_package, actions)
    actions.sort_by(&:priority).each { |a| a.apply(work_package) }
  end

  def append_id(sym)
    "#{sym.to_s.chomp('_id')}_id"
  end
end
