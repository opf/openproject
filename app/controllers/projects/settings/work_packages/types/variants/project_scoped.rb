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

module Projects::Settings::WorkPackages::Types::Variants
  # Re-homes a global type-administration tab inside a project's settings. The tab bodies
  # are the administration ones untouched; what changes is who may reach them and which
  # types they can name at all.
  #
  # The inherited lookup is dropped and re-registered rather than prepended. Prepending put
  # it and #authorize ahead of ApplicationController's user_setup, so User.current was still
  # anonymous, Project.visible found nothing and every request bounced to the login page.
  # Request specs cannot see that: login_as sets User.current directly, so they pass either
  # way. Each including controller re-adds :find_type for the actions that need one.
  module ProjectScoped
    extend ActiveSupport::Concern
    include ::WorkPackageTypes::TypeVariantsFeature

    included do
      layout "base"
      menu_item :settings_work_packages

      skip_before_action :require_admin
      skip_before_action :find_type, raise: false

      before_action :find_project_by_project_id
      before_action :authorize
      before_action :require_type_variants_feature
    end

    private

    # A variant of another project is absent rather than forbidden, so a project
    # administrator cannot tell the two apart by probing ids.
    def find_type
      @type = @project.owned_types.find_by(id: params[:variant_id])

      render_404 if @type.nil?
    end

    def type_routes
      @type_routes ||= ::WorkPackageTypes::TypeRoutes.for(@type, project: @project)
    end
  end
end
