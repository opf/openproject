# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackages::CreateService < BaseServices::BaseCallable
  include ::WorkPackages::Shared::UpdateAncestors
  include ::Shared::ServiceContext
  include Types::ApplyPatterns

  attr_reader :user, :contract_class, :contract_options

  def initialize(user:, contract_class: WorkPackages::CreateContract, contract_options: {})
    super()
    @user = user
    @contract_class = contract_class
    @contract_options = contract_options
  end

  def perform
    attributes = params.except(:send_notifications, :work_package)
    work_package = params[:work_package] || WorkPackage.new

    in_user_context(send_notifications: params[:send_notifications]) do
      create(attributes, work_package)
    end
  end

  protected

  def create(attributes, work_package)
    result = set_attributes(attributes, work_package)

    if result.success?
      # Set attributes service passed, meaning the contract is fulfilled.
      # Avoid running validations again as we might be in a project copy scenario.
      work_package.attachments = work_package.attachments_replacements if work_package.attachments_replacements
      work_package.save(validate: false)

      apply_patterns(work_package)

      # update ancestors before rescheduling, as the parent might switch to automatic mode
      multi_update_ancestors(result.all_results).each do |ancestor_result|
        result.merge!(ancestor_result)
      end

      result.merge!(reschedule_related(work_package))

      set_user_as_watcher(work_package)
    end

    result
  end

  def set_attributes(attributes, work_package)
    attributes_service_class.new(user:, model: work_package, contract_class:, contract_options:).call(attributes)
  end

  def reschedule_related(work_package)
    # Force work package to keep its scheduling mode if it's automatic.
    # This is necessary in bulk duplicate scenarios.
    switching_to_automatic_mode = []
    switching_to_automatic_mode << work_package if work_package.schedule_automatically?
    rescheduling_result = WorkPackages::SetScheduleService.new(user:, work_package:, switching_to_automatic_mode:).call

    persist_reschedule_changes(rescheduling_result)

    rescheduling_result
  end

  def persist_reschedule_changes(rescheduling_result)
    rescheduling_result.self_and_dependent
          .filter { it.result.changed? }
          .each do |r|
      unless r.result.save
        rescheduling_result.success = false
        r.errors = r.result.errors
      end
    end
  end

  def set_user_as_watcher(work_package)
    # We don't care if it fails here. If it does
    # the user simply does not become watcher
    Services::CreateWatcher.new(work_package, user).run(send_notifications: false)
  end

  def attributes_service_class
    ::WorkPackages::SetAttributesService
  end
end
