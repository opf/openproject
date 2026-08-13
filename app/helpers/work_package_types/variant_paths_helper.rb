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
  # Where a variant is being configured from.
  #
  # The tab screens are mounted twice — once under /types for administration, once under a
  # project's settings for the variants a project owns — from one set of components. Those
  # components name the administration route they mean and this translates it, rather than each
  # of them learning that there are two of everything. The project mount differs only by a
  # prefix on the helper name and the project in the path, which is why one rewrite serves all
  # of them.
  #
  # Some routes exist in administration alone, on purpose: picking the projects a type is used
  # in, choosing what a configuration inherits from, copying a workflow from any type or role.
  # Those have no counterpart to rewrite to, and #scoped_variant_route? is how a component asks
  # whether the control it is about to render has a home here at all.
  module VariantPathsHelper
    PROJECT_SCOPE_PREFIX = "project_settings_work_packages_"

    # rubocop:disable Rails/HelperInstanceVariable
    def variant_scope_project = @project
    # rubocop:enable Rails/HelperInstanceVariable

    def scoped_variant_path(helper, **args)
      name = scoped_variant_path_helper_name(helper)

      unless respond_to?(name)
        raise ArgumentError,
              "#{helper} has no counterpart under a project's settings. Ask scoped_variant_route? " \
              "before rendering a control that only administration has."
      end

      public_send(name, **scoped_variant_path_scope_args, **args)
    end

    def scoped_variant_route?(helper) = respond_to?(scoped_variant_path_helper_name(helper))

    # For a control that simply is not offered outside administration: nil rather than a raise,
    # so the caller can drop it without asking twice.
    def scoped_variant_path_if_available(helper, **args)
      scoped_variant_path(helper, **args) if scoped_variant_route?(helper)
    end

    # The arguments identifying the variant, which every one of these routes takes. Absent a
    # variant the URL is about the type itself, whose configuration is its base variant.
    def variant_path_args(variant = nil, type = nil)
      variant&.path_args || { type_id: type&.id }
    end

    private

    def scoped_variant_path_helper_name(helper)
      return helper.to_s if variant_scope_project.nil?

      # No \b before it: an underscore is a word character, so "edit_type_details_path" has no
      # boundary ahead of "type_" to anchor to.
      helper.to_s.sub(/types?_/) { "#{PROJECT_SCOPE_PREFIX}#{Regexp.last_match(0)}" }
    end

    def scoped_variant_path_scope_args
      return {} if variant_scope_project.nil?

      # The object, not its id, so the path carries the identifier like every other project URL.
      { project_id: variant_scope_project }
    end
  end
end
