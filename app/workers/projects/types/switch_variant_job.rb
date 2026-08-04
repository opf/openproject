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

module Projects
  module Types
    # Runs a type switch off-request. The service re-types every work package
    # through WorkPackages::UpdateService, which journals and notifies per
    # record, so a large family takes far longer than a request may last.
    class SwitchVariantJob < ApplicationJob
      include WorkPackageTypes::SwitchFailureMessages

      # Discriminates our status rows from those of any other job that comes to
      # reference a project.
      KIND = "type_switch"

      queue_with_priority :above_normal

      def perform(user:, project:, source:, target:)
        result = SwitchVariantService.new(user:, model: project).call(source:, target:)

        if result.success?
          upsert_status status: :success,
                        message: I18n.t("projects.settings.types.switch_dialog.success",
                                        type: target.composite_name)
        else
          upsert_status status: :failure, message: switch_failure_messages(result).join(", ")
        end

        result
      end

      def store_status? = true

      def updates_own_status? = true

      protected

      # Stamped on every status update, including the in_queue row the enqueue
      # listener writes, so the row is self-describing from the moment it exists.
      #
      # The project lives in the payload rather than in status_reference because
      # job_statuses holds a unique index on its polymorphic reference: a project
      # is switched repeatedly, so the second switch would collide there — and
      # upsert_status retries RecordNotUnique without bound.
      def build_status_attributes(attributes)
        payload = (attributes[:payload] || {}).merge(
          kind: KIND,
          project_id: params[:project].id,
          source_id: params[:source].id,
          target_id: params[:target].id
        )

        super(attributes.merge(payload:))
      end

      private

      def params
        arguments.is_a?(Array) ? Hash(arguments.first) : {}
      end
    end
  end
end
