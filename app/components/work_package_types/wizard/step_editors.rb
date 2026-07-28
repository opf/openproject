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
    # Steps whose fields belong to the wizard form itself, so that "Continue" persists
    # them when advancing. Each editor owns what its step needs — the form class, the
    # object it binds to, and any reuse mode — so PageComponent stays a shell that only
    # asks for those, never for a particular step.
    module StepEditors
      def self.for(step, type)
        case step
        when :details then Details.new(type)
        when :defaults then Defaults.new(type)
        when :workflows then Workflows.new(type)
        end
      end

      class Base
        def initialize(type)
          @type = type
        end

        attr_reader :type

        def aspect = nil

        def linkable_aspect? = aspect.present?

        def model = type

        # A Primer form class whose fields the wizard form submits, or nil for editors
        # that render their inputs themselves.
        def form_class = nil

        # A component rendered inside the wizard form, for editors that are not
        # expressible as a Primer form.
        def body = nil

        # Data attributes for the form element, e.g. Stimulus wiring.
        def form_data = {}

        # Whether the step's frame reloads from the current location rather than from the
        # step's own path, so that in-frame selections survive an out-of-band reload.
        def reload_from_location? = false

        def readonly? = linkable_aspect? && type.linked?(aspect)
      end

      class Details < Base
        def form_class = WorkPackageTypes::DetailsForm
      end

      class Defaults < Base
        def form_class = WorkPackageTypes::DefaultsForm

        def aspect = Type::ConfigurationLink::DEFAULTS

        def model
          @model ||= Forms::DefaultsFormModel.build(type)
        end

        # Without this the pattern input cannot be toggled as the subject mode changes.
        def form_data = readonly? ? {} : model.stimulus_data
      end

      # The transition matrix renders its own inputs rather than a Primer form, and it
      # supplies no save control of its own — the wizard's Continue submits it.
      class Workflows < Base
        def aspect = Type::ConfigurationLink::WORKFLOWS

        def body = WorkflowsStepComponent.new(type:)

        # The matrix keeps the selected roles and transition tab in the page URL, which a
        # reload from the step path would discard.
        def reload_from_location? = true
      end
    end
  end
end
