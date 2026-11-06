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

module WorkPackages
  module DatePicker
    class InitialValuesForm < ApplicationForm
      attr_reader :work_package

      def initialize(work_package:, is_milestone:)
        super()

        @work_package = work_package
        @is_milestone = is_milestone
      end

      form do |form|
        hidden_initial_field(form, name: :start_date)
        hidden_initial_field(form, name: :ignore_non_working_days)
        hidden_initial_field(form, name: :schedule_manually)

        unless @is_milestone
          hidden_initial_field(form, name: :due_date)
          hidden_initial_field(form, name: :duration)
        end
      end

      private

      def hidden_initial_field(form, name:)
        form.hidden(name:,
                    value: work_package.public_send(:"#{name}_was"),
                    data: { "work-packages--date-pick--preview-target": "initialValueInput",
                            "referrer-field": name })
      end
    end
  end
end
