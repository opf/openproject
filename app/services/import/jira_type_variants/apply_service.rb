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

module Import
  module JiraTypeVariants
    class ApplyService
      def initialize(user:, jira_import:)
        @user = user
        @find_or_create_service = FindOrCreateService.new(user:, jira_import:)
      end

      def call(type:, project:)
        find_or_create_service
          .call(type:, project:)
          .bind { |variant| apply(type:, project:, variant:) }
      end

      private

      attr_reader :user, :find_or_create_service

      def apply(type:, project:, variant:)
        current_variant = project.enabled_variants.find_by(type:)
        return ServiceResult.success(result: variant) if current_variant == variant

        service_call = add_or_switch_variant(current_variant:, variant:, project:)
        service_call.map { variant }
      end

      def add_or_switch_variant(current_variant:, variant:, project:)
        if current_variant
          Projects::Types::SwitchVariantService
            .new(user:, model: project)
            .call(source: current_variant, target: variant)
        else
          Projects::Types::AddService
            .new(user:, model: project)
            .call(variant:)
        end
      end
    end
  end
end
