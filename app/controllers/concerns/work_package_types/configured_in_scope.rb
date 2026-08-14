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
  # The variant configuration screens answer at two addresses: under /types for administration,
  # and inside the settings of a project that owns a variant. One route with an optional project
  # prefix serves both, so a single controller answers both and this is where it learns which.
  #
  # Everything keys off the URL. A path carrying a project is that project's business and is
  # authorized with its permission; a path without one is administration's. Chrome, menu,
  # breadcrumb and the tab set follow the same signal, so the two never disagree.
  module ConfiguredInScope
    extend ActiveSupport::Concern
    include ::WorkPackageTypes::TypeVariantsFeature

    class_methods do
      # Screens administration alone has: which projects use a type, and which variant a new
      # project starts with. Declared here rather than as a callback of the controller's own so
      # that it is answered in the right place — after the current user is known, so the refusal
      # renders in the signed-in chrome, and before #authorize, which would otherwise raise on a
      # permission the map deliberately does not define for a project.
      def administration_only!(*actions)
        self.administration_only_actions = actions.presence || :all
      end
    end

    included do
      # Both are resolved per request rather than declared, since the same class serves both.
      layout -> { variant_scope_project ? "base" : "admin" }

      class_attribute :administration_only_actions, default: nil

      before_action :reject_administration_only_screen

      # Declared as two mutually exclusive sets rather than one guard of our own, so that the
      # methods doing the authorizing are the ones named here: Accounts::Authorization credits a
      # controller by the callback's name, and would not see require_admin called from inside
      # something else. They also land where administration's own check ran — after
      # ApplicationController#user_setup, so the current user is known, and before any callback a
      # controller adds of its own, which read what these resolve.
      before_action :require_admin, unless: :variant_scope_requested?
      before_action :find_project_by_project_id, :authorize, :require_type_variants_feature,
                    if: :variant_scope_requested?
    end

    # Inside a project the menu is that project's work package settings, whatever the controller
    # declared for administration. Overridden here rather than in each controller's own
    # current_menu_item block, of which there are ten and all of them name administration's.
    def current_menu_item
      return :settings_work_packages if variant_scope_project

      super
    end

    # Keeps the project in every path these screens render, so a component names a route without
    # knowing which of the two addresses it is answering at.
    def default_url_options
      return super unless variant_scope_requested?

      super.merge(project_id: params[:project_id])
    end

    private

    def variant_scope_requested? = params[:project_id].present?

    def variant_scope_project = @project

    # Reaching an administration-only screen with a project in the path is absent rather than
    # forbidden: the project simply has no such page.
    def reject_administration_only_screen
      return unless variant_scope_requested?
      return if administration_only_actions.nil?
      return unless administration_only_actions == :all ||
                    administration_only_actions.include?(action_name.to_sym)

      render_404
    end

    # Narrowed to the variants a project may configure when one is asking. Another project's is
    # absent rather than forbidden, so its ids cannot be probed.
    def addressed_variant(among: nil)
      return super if variant_scope_project.nil?

      scope = (among || ::TypeVariant.all).non_default_variants.owned_by(variant_scope_project)
      found = scope.find_by(id: params[:variant_id])
      render_404 if found.nil?

      found
    end
  end
end
