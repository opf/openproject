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
    # The steps of the sub-type creation wizard, in order. Every step submits its form
    # through the wizard controller, which persists it and advances.
    module Steps
      ALL = %i[details form_configuration workflows automations projects pdf].freeze

      # The configuration aspect each step chooses a reuse mode for. Details has none:
      # it names the type, so there is nothing to reuse from a source.
      STEP_ASPECTS = {
        form_configuration: Type::ConfigurationLink::FORM_CONFIGURATION,
        workflows: Type::ConfigurationLink::WORKFLOWS,
        automations: Type::ConfigurationLink::AUTOMATIONS,
        projects: Type::ConfigurationLink::PROJECTS,
        pdf: Type::ConfigurationLink::PDF_EXPORT
      }.freeze

      module_function

      def aspect_for(step) = STEP_ASPECTS[step]

      def title(step) = I18n.t("types.creation_wizard.steps.#{step}")

      def all = ALL

      def first = ALL.first

      def last = ALL.last

      def for_key(key)
        return nil if key.blank?

        ALL.find { |step| step == key.to_sym }
      end

      def index(step) = ALL.index(step)

      def next_after(step)
        idx = ALL.index(step)
        ALL[idx + 1] if idx && idx + 1 < ALL.length
      end

      def previous_before(step)
        idx = ALL.index(step)
        ALL[idx - 1] if idx&.positive?
      end
    end
  end
end
