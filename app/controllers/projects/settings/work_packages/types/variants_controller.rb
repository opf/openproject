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

class Projects::Settings::WorkPackages::Types::VariantsController < Projects::SettingsController
  include ::WorkPackageTypes::TypeVariantsFeature

  menu_item :settings_work_packages

  before_action :require_type_variants_feature
  before_action :find_variant, only: %i[destroy]

  # The project's variants are listed by the types page itself, under the family they
  # belong to, so this resource only ever writes.
  def destroy
    @variant.destroy!

    redirect_to project_settings_work_packages_types_path(@project), status: :see_other
  end

  private

  # Scoping the lookup to the project is the isolation. A variant of another project is
  # absent rather than forbidden, so the two cases are indistinguishable from outside.
  def find_variant
    @variant = @project.owned_types.find_by(id: params[:id])

    render_404 if @variant.nil?
  end
end
