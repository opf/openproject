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
  module Wizard
    class SidebarComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(type:, current_step:)
        super(type)

        @current_step = current_step
      end

      LEADING_ICONS = {
        details: :info,
        form_configuration: :"list-unordered",
        workflows: :"git-branch",
        automations: :zap,
        projects: :table,
        pdf: :file
      }.freeze

      private

      attr_reader :current_step

      def type = model

      def steps = Steps.all

      def leading_icon(step) = LEADING_ICONS.fetch(step.key)

      def current?(step) = step == current_step

      # Steps ordered before the current one are considered done. Until the
      # record is created (step 1) nothing is navigable or completed yet.
      def completed?(step)
        type.persisted? && Steps.index(step) < Steps.index(current_step)
      end

      # Only visited/creatable steps are navigable: before the record exists we
      # cannot address a step by its type id.
      def href_for(step)
        type_creation_wizard_path(type, step: step.key) if type.persisted?
      end
    end
  end
end
