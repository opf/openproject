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

##
# Calls a service in a background job.
#
# Example:
#
#   CallServiceJob.perform_later(
#     "Members::AddRoleService",
#     { user_id: 42, role_id: 7, project_id: nil, send_notifications: false },
#     check_pending_migrations: true
#   )
class CallServiceJob < ApplicationJob
  class ServiceCallFailed < StandardError; end

  # Transient errors are retried
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  # If there are pending migrations wait for up to an hour (well 78 minutes altogether)
  # for them to finish before giving up
  retry_on ActiveRecord::PendingMigrationError, wait: :polynomially_longer, attempts: 7

  # Service result failures are permanent — fail the job immediately without retry.
  # Declared after retry_on StandardError so it takes precedence for ServiceCallFailed.
  retry_on ServiceCallFailed, attempts: 1

  queue_with_priority :low

  # @param service_class_name [String] Fully-qualified service class name
  # @param kwargs [Hash] Keyword arguments forwarded to service.call(...)
  # @param current_user_id [Integer, nil] Current user ID; nil uses the system user
  # @param check_pending_migrations [Boolean] Ensure this job is not executed while there are migrations pending.
  def perform(service_class_name, kwargs, current_user_id: User.system.id, check_pending_migrations: false)
    ActiveRecord::Migration.check_pending_migrations if check_pending_migrations

    service = service_class_name.constantize.new current_user: User.find(current_user_id)
    result = service.call **kwargs.symbolize_keys

    result.on_failure do |r|
      raise ServiceCallFailed, "#{service_class_name}#call failed: #{r.message}"
    end
  end
end
