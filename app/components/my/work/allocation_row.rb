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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module My
  module Work
    class AllocationRow < OpPrimer::BorderBoxRowComponent
      include Redmine::I18n

      Entry = Data.define(:scheduled_entry, :visible, :hours) do
        delegate :work_package, :allocated_on, to: :scheduled_entry

        alias_method :visible?, :visible
      end

      delegate :work_package, to: :allocation

      def button_links
        [render(My::Work::AllocationActionMenuComponent.new(allocation:))]
      end

      def spent_on
        format_date(allocation.allocated_on)
      end

      def time; end

      def hours
        DurationConverter.output(allocation.hours, format: :hours_and_minutes)
      end

      def type
        concat(render(Primer::Beta::Octicon.new(icon: :"op-person-assigned", mr: 1)))

        ResourceAllocation.model_name.human
      end

      def subject
        return hidden_work_package unless allocation.visible?

        render(Primer::OpenProject::FlexLayout.new) do |flex|
          flex.with_row do
            render(WorkPackages::InfoLineComponent.new(work_package:))
          end
          flex.with_row do
            render(Primer::Beta::Text.new(font_weight: :semibold)) { work_package.subject }
          end
        end
      end

      def project
        return unless allocation.visible?

        render(Primer::Beta::Link.new(href: project_path(work_package.project), underline: true)) do
          work_package.project.name
        end
      end

      private

      def hidden_work_package
        render(Primer::Beta::Text.new(color: :muted)) { t("resource_management.my_work.hidden_work_package") }
      end

      def allocation
        model
      end
    end
  end
end
