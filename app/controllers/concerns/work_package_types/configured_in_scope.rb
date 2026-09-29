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
  # Which of the two addresses a variant configuration screen is answering at, read from the URL.
  # Layout, menu, breadcrumb, page title, the tab set and the variants a lookup considers all key
  # off it, so nothing here may resolve the scope another way.
  module ConfiguredInScope
    extend ActiveSupport::Concern
    include ::WorkPackageTypes::TypeVariantsFeature

    class_methods do
      # Answered after ApplicationController#user_setup, so the refusal renders in the signed-in
      # chrome, and before #authorize, which raises on a permission the map does not define for a
      # project.
      def administration_only!(*actions)
        self.administration_only_actions = actions.presence || :all
      end
    end

    included do
      layout -> { variant_scope_project ? "base" : "admin" }

      class_attribute :administration_only_actions, default: nil

      before_action :reject_administration_only_screen

      # Accounts::Authorization credits a controller by the callback's name, so these have to be
      # named here rather than called from a guard of our own. Both run after user_setup and
      # before any callback a controller adds, which read what they resolve.
      before_action :require_admin, unless: :variant_scope_requested?
      before_action :find_project_by_in_project_id, :authorize, :require_type_variants_feature,
                    if: :variant_scope_requested?
    end

    def current_menu_item
      return :settings_work_packages if variant_scope_project

      super
    end

    private

    # Not :project_id: the projects tab takes one of those, naming a project in its list rather
    # than the one asking.
    def variant_scope_requested? = params[:in_project_id].present?

    def find_project_by_in_project_id
      @project = Project.visible.find(params.expect(:in_project_id))
    end

    def variant_scope_project = @project

    # 404 rather than 403: the project has no such page.
    def reject_administration_only_screen
      return unless variant_scope_requested?
      return if administration_only_actions.nil?
      return unless administration_only_actions == :all ||
                    administration_only_actions.include?(action_name.to_sym)

      render_404
    end

    # 404 rather than 403, so another project's variant ids cannot be probed.
    def addressed_variant(among: nil)
      return super if variant_scope_project.nil?

      scope = (among || ::TypeVariant.all).non_default_variants.owned_by(variant_scope_project)
      found = scope.find_by(id: params[:variant_id])
      render_404 if found.nil?

      found
    end
  end
end
