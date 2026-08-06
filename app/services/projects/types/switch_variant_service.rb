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
    # Moves a project from one variant of a family to another member of it (a sibling
    # variant or the shared root). The project's work packages are untouched: they store
    # the root either way, so the switch is a change of which configuration the project
    # resolves to, not a retype.
    class SwitchVariantService < BaseService
      private

      def persist(service_call)
        source = params[:source]
        target = params[:target]

        if !source.variant?
          failure(:switch_source_not_a_variant)
        elsif source == target
          failure(:switch_target_identical)
        elsif source.root_id != target.root_id
          failure(:switch_target_not_in_family)
        else
          switch(target)
          service_call
        end
      end

      def switch(target)
        current_project_type = model.project_types.find_by!(type_id: target.root_id)

        if target.variant?
          current_project_type.update!(variant: target)
        else
          current_project_type.update!(variant: nil)
        end

        enable_work_package_custom_fields(target)
      end
    end
  end
end
