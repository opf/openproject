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
      def self.for(step, variant)
        case step
        when :details then Details.new(variant)
        when :defaults then Defaults.new(variant)
        when :workflows then Workflows.new(variant)
        end
      end

      class Base
        def initialize(variant)
          @variant = variant
        end

        attr_reader :variant

        def aspect = nil

        def linkable_aspect? = aspect.present?

        def model = variant

        def editor(_builder)
          raise SubclassResponsibilityError
        end

        def form_data = {}

        def reload_from_location? = false

        def readonly? = linkable_aspect? && variant.linked?(aspect)
      end

      class Details < Base
        def editor(builder) = WorkPackageTypes::DetailsForm.new(builder)
      end

      class Defaults < Base
        def editor(builder) = WorkPackageTypes::DefaultsForm.new(builder)

        def aspect = TypeVariant::DEFAULTS

        def model
          @model ||= Forms::DefaultsFormModel.build(variant)
        end

        # Without this the pattern input cannot be toggled as the subject mode changes.
        def form_data = readonly? ? {} : model.stimulus_data
      end

      class Workflows < Base
        def aspect = TypeVariant::WORKFLOWS

        # The workflow matrix editor is not using a primer form, thus it does not consume the builder
        # It can internally switch what tab it is editing, those trigger a submit to its own controller action.
        # The submit of the final page happens through the wizard's continue button
        def editor(_builder) = WorkflowsStepComponent.new(variant:)

        # The matrix keeps the selected roles and transition tab in the page URL, which a
        # reload from the step path would discard.
        def reload_from_location? = true
      end
    end
  end
end
