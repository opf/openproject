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
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects::Settings::WorkPackages::Types::Variants
  module WorkflowCopies
    # The submit behind the copy dialog. Its source and targets are scoped by the parent to what
    # the addressed variant may exchange configuration with, whoever is asking.
    class FromRolesController < ::Workflows::Copies::FromRolesController
      include ::WorkPackageTypes::TypeVariantsFeature

      layout "base"
      menu_item :settings_work_packages

      skip_before_action :require_admin

      # The inherited lookups are dropped and re-registered rather than prepended: they must run
      # after ApplicationController's user_setup, or User.current is anonymous and Project.visible
      # finds nothing, and before the parent's own callbacks, which read what they resolve. See
      # ProjectScoped for the same reasoning on the tabs.
      skip_before_action :set_source_variant
      skip_before_action :set_source_role
      skip_before_action :set_target_roles

      before_action :find_project_by_project_id
      before_action :authorize
      before_action :require_type_variants_feature
      before_action :set_source_variant
      before_action :set_source_role
      before_action :set_target_roles

      private

      # A variant of another project is absent rather than forbidden.
      def addressed_variant(among: nil)
        scope = among || ::TypeVariant.all
        found = scope.non_default_variants.owned_by(@project).find_by(id: params[:variant_id])
        render_404 if found.nil?

        found
      end
    end
  end
end
