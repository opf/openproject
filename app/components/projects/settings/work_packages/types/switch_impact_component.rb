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

module Projects
  module Settings
    module WorkPackages
      module Types
        # What the chosen switch will do. Streamable on its own so choosing a
        # target repaints it without re-rendering the form and moving focus off
        # the select.
        class SwitchImpactComponent < ApplicationComponent
          include OpPrimer::ComponentHelpers
          include OpTurbo::Streamable

          Section = Data.define(:id, :heading, :fields)

          def initialize(impact:)
            super()

            @impact = impact
          end

          private

          attr_reader :impact

          def field_sections
            [
              Section.new(id: "hidden",
                          heading: t("projects.settings.types.switch.impact.hidden_heading"),
                          fields: impact.hidden_fields),
              Section.new(id: "new",
                          heading: t("projects.settings.types.switch.impact.new_heading"),
                          fields: impact.new_fields)
            ].reject { it.fields.empty? }
          end

          def field_suffix(field)
            if field.kind == :table
              t("projects.settings.types.switch.impact.table_suffix")
            elsif (count = impact.value_count(field))
              t("projects.settings.types.switch.impact.value_count", count:)
            end
          end
        end
      end
    end
  end
end
