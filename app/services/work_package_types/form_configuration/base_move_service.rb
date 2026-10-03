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

module WorkPackageTypes
  module FormConfiguration
    class BaseMoveService < ::BaseServices::BaseCallable
      include LayoutLock

      def initialize(user:, form_configuration:, record:)
        super()
        @user = user
        @form_configuration = form_configuration
        @record = record
      end

      protected

      def perform(*)
        return unauthorized unless user.admin?

        with_layout_lock(form_configuration) do
          record = fresh_record
          record ? move(record) : invalid_move
        end
      rescue ActiveRecord::RecordNotFound
        raise
      rescue StandardError => e
        OpenProject.logger.error(e, reference: :form_configuration_move, form_configuration_id: form_configuration.id)
        ServiceResult.failure(message: I18n.t("types.edit.form_configuration.move_failed"))
      end

      private

      attr_reader :user, :form_configuration

      def fresh_record = raise(SubclassResponsibilityError)

      def move(_record) = raise(SubclassResponsibilityError)

      def invalid_move
        ServiceResult.failure(message: I18n.t(:error_invalid_list_move_anchor))
      end

      def unauthorized
        ServiceResult.failure(message: I18n.t("activerecord.errors.messages.error_unauthorized"))
      end
    end
  end
end
