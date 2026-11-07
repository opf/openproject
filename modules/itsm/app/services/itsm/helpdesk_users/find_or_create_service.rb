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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ITSM
  module HelpdeskUsers
    class FindOrCreateService < ::BaseServices::BaseCallable
      include Dry::Monads[:result]

      PERMISSIONS = %i[view_work_packages add_work_packages add_work_package_comments].freeze

      protected

      def perform
        find_existing
          .or { in_transaction { locked { find_or_create_role.bind { find_or_create_user } } } }
          .either(->(user) { ServiceResult.success(result: user) },
                  ->(record) { ServiceResult.failure(errors: record.errors) })
      end

      private

      def find_existing
        find(ProjectRole, Setting.helpdesk_role_id).bind { find(ServiceAccount, Setting.helpdesk_user_id) }
      end

      def find_or_create_role
        find_or_create(ProjectRole, :helpdesk_role_id) do
          ProjectRole.new(name: translated(:label_helpdesk_role), permissions: PERMISSIONS)
        end
      end

      def find_or_create_user
        find_or_create(ServiceAccount, :helpdesk_user_id) { ServiceAccount.new(name: translated(:label_helpdesk_user)) }
      end

      def find_or_create(model, setting)
        find(model, Setting[setting]).or do
          persist(yield).fmap { |record| record.tap { Setting[setting] = it.id } }
        end
      end

      def find(model, id) = model.find_by(id:).then { it ? Success(it) : Failure() }

      def persist(record) = record.save ? Success(record) : Failure(record)

      def locked(&) = OpenProject::Mutex.with_advisory_lock(ServiceAccount, "itsm_helpdesk_user", transaction: true, &)

      def in_transaction
        result = nil
        ActiveRecord::Base.transaction(requires_new: true) do
          result = yield
          raise ActiveRecord::Rollback if result.failure?
        end
        result
      end

      def translated(key) = I18n.t(key, locale: Setting.default_language)
    end
  end
end
