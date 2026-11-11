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
    class SetUpService < ::BaseServices::BaseCallable
      PERMISSIONS = %i[view_work_packages add_work_packages add_work_package_comments].freeze

      protected

      def perform
        return ServiceResult.success if ITSM.helpdesk_role && ITSM.helpdesk_user

        in_transaction { locked { create_missing } }
      end

      private

      def create_missing
        role = ITSM.helpdesk_role || create(new_role, :helpdesk_role_id)
        return ServiceResult.failure(errors: role.errors) unless role.persisted?

        user = ITSM.helpdesk_user || create(new_user, :helpdesk_user_id)
        user.persisted? ? ServiceResult.success : ServiceResult.failure(errors: user.errors)
      end

      def new_role = ProjectRole.new(name: translated(:label_helpdesk_role), permissions: PERMISSIONS)

      def new_user = ServiceAccount.new(name: translated(:label_helpdesk_user))

      def create(record, setting)
        definition = Settings::Definition[setting]
        return configured_record_missing(record, definition) unless definition.writable?

        record.tap { Setting[setting] = it.id if it.save }
      end

      def configured_record_missing(record, definition)
        message = I18n.t("itsm.helpdesk_users.configured_record_missing",
                         variable: definition.possible_env_names.first,
                         id: definition.value)
        record.tap { it.errors.add(:base, message) }
      end

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
