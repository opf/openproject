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

# What a switch would do, as a subresource of the switch that would do it.
class Projects::Settings::WorkPackages::Types::Switches::ImpactsController < Projects::SettingsController
  include WorkPackageTypes::TypeVariantsFeature
  include OpTurbo::ComponentStream
  include WorkPackageTypes::SwitchLookup

  menu_item :settings_work_packages

  before_action :require_type_variants_feature
  before_action :load_source

  # POST rather than GET, even though nothing is persisted and nothing changes:
  # the choice arrives as the switch form's body, which keeps it out of the
  # address bar and reuses the refresh mechanism every other live preview in
  # the app is built on.
  def create
    update_via_turbo_stream(
      component: Projects::Settings::WorkPackages::Types::SwitchImpactComponent.new(impact: chosen_impact)
    )

    respond_to_with_turbo_streams
  end

  private

  # Nothing to report while the selection is still the member in force, which is what the
  # dialog opens on. The family check is a backstop the select makes unreachable, keeping this
  # endpoint from describing a pair SwitchVariantContract would refuse.
  def chosen_impact
    target = ::TypeVariant.find_by(id: params[:target_id])
    return if target.nil? || target == @source || target.type_id != @source.type_id

    ::Projects::Types::Switch::Impact.new(project: @project, source: @source, target:)
  end
end
