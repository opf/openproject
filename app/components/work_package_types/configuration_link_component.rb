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
  # Mode chooser (Independent/Linked) + source picker, shared by the PDF and
  # subject tabs. When Independent, the tab's own editor (passed as the block
  # content) shows; picking Linked swaps it for the source picker + Save.
  # Toggling is client-side via the show-when-value-selected controller.
  class ConfigurationLinkComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpPrimer::FormHelpers

    def initialize(type:, aspect:)
      @aspect = aspect
      super(type)
    end

    def type = model

    def feature_active? = OpenProject::FeatureDecisions.subtypes_active?

    def linked? = type.linked?(@aspect)

    def current_source = type.source_for(@aspect)

    def form_options
      {
        url: type_configuration_link_path(type_id: type.id, aspect: @aspect),
        method: :put,
        linked: linked?,
        current_source_id: current_source&.id,
        source_options:
      }
    end

    private

    def source_options
      Type.global.where.not(id: type.id).order(:name)
    end
  end
end
