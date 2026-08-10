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
    # The steps of the variant creation wizard, in order. Every step submits its form
    # through the wizard controller, which persists it and advances.
    module Steps
      ALL = %i[details defaults form_configuration project_attributes workflows projects pdf].freeze

      # Picking the projects to use a type in has nothing to offer a project-owned variant:
      # it may only ever be activated in the project owning it. Keyed off the type rather
      # than off where it is being administered from, because that rule holds for an
      # instance administrator editing the variant too.
      OWNED_ONLY_EXCLUDED = %i[projects].freeze

      module_function

      def title(step) = I18n.t("types.creation_wizard.steps.#{step}")

      def all = ALL

      def available_for(type)
        type.project_owned? ? ALL - OWNED_ONLY_EXCLUDED : ALL
      end

      def available?(step, type) = available_for(type).include?(step)

      def first = ALL.first

      def last = ALL.last

      def last_for(type) = available_for(type).last

      def for_key(key)
        return nil if key.blank?

        ALL.find { |step| step == key.to_sym }
      end

      def index(step) = ALL.index(step)

      def next_after(step, type = nil)
        steps = type ? available_for(type) : ALL
        idx = steps.index(step)
        steps[idx + 1] if idx && idx + 1 < steps.length
      end

      def previous_before(step, type = nil)
        steps = type ? available_for(type) : ALL
        idx = steps.index(step)
        steps[idx - 1] if idx&.positive?
      end
    end
  end
end
