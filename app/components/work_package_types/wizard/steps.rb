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

      # Keyed off the variant, not off where it is configured from: a variant a project owns may
      # only ever be used there, for an administrator too.
      OWNED_EXCLUDED = %i[projects].freeze

      module_function

      def title(step) = I18n.t("types.creation_wizard.steps.#{step}")

      def all = ALL

      # While a type is being created the wizard holds the type itself in the variant slot, and a
      # type is owned by no project, so #try rather than a plain send.
      def available_for(variant)
        variant.try(:project_owned?) ? ALL - OWNED_EXCLUDED : ALL
      end

      def available?(step, variant) = available_for(variant).include?(step)

      def last_for(variant) = available_for(variant).last

      def first = ALL.first

      def last = ALL.last

      def for_key(key)
        return nil if key.blank?

        ALL.find { |step| step == key.to_sym }
      end

      def index(step) = ALL.index(step)

      def next_after(step, variant = nil)
        steps = available_for(variant)
        idx = steps.index(step)
        steps[idx + 1] if idx && idx + 1 < steps.length
      end

      def previous_before(step, variant = nil)
        steps = available_for(variant)
        idx = steps.index(step)
        steps[idx - 1] if idx&.positive?
      end
    end
  end
end
