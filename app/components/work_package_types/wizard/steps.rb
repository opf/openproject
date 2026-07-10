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
    # A single step in the sub-type creation wizard.
    #
    # +submit+ marks steps whose "Continue" action persists a form through the
    # wizard controller (Details, Workflows, Projects). The remaining steps
    # self-persist through their embedded turbo endpoints, so their "Continue"
    # is plain navigation to the next step.
    Step = Data.define(:key, :submit) do
      def submit? = submit

      def title = I18n.t("types.creation_wizard.steps.#{key}")
    end

    module Steps
      ALL = [
        Step.new(key: :details, submit: true),
        Step.new(key: :form_configuration, submit: false),
        Step.new(key: :workflows, submit: true),
        Step.new(key: :automations, submit: false),
        Step.new(key: :projects, submit: false),
        Step.new(key: :pdf, submit: false)
      ].freeze

      module_function

      def all = ALL

      def first = ALL.first

      def last = ALL.last

      def for_key(key)
        return nil if key.blank?

        ALL.find { |step| step.key == key.to_sym }
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
