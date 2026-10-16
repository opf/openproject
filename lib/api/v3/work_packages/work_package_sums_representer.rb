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

require "roar/decorator"

module API
  module V3
    module WorkPackages
      class WorkPackageSumsRepresenter < ::API::Decorators::Single
        extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass
        include ::API::Decorators::DateProperty

        custom_field_injector(injector_class: ::API::V3::Utilities::CustomFieldSumInjector)

        def initialize(sums)
          # breaking inheritance law here
          super(sums, current_user: nil)
        end

        def self.create(sums, current_user)
          create_class(Schema::WorkPackageSumsSchema.new, current_user).new(sums)
        end

        property :estimated_time,
                 exec_context: :decorator,
                 getter: ->(*) {
                   datetime_formatter.format_duration_from_hours(represented.estimated_hours,
                                                                 allow_nil: true)
                 }

        property :story_points,
                 render_nil: true

        property :percentage_done,
                 render_nil: true,
                 getter: ->(*) {
                   done_ratio
                 }

        property :remaining_time,
                 render_nil: true,
                 exec_context: :decorator,
                 getter: ->(*) {
                   datetime_formatter.format_duration_from_hours(represented.remaining_hours,
                                                                 allow_nil: true)
                 }
      end
    end
  end
end
