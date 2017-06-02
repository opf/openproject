#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module WorkPackages
      class WorkPackagePayloadRepresenter < Roar::Decorator
        include Roar::JSON::HAL
        include Roar::Hypermedia

        class << self
          def create_class(work_package)
            injector_class = ::API::V3::Utilities::CustomFieldInjector
            injector_class
              .create_value_representer_for_property_patching(work_package,
                                                              WorkPackagePayloadRepresenter)
          end

          def create(work_package)
            create_class(work_package).new(work_package)
          end
        end

        self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

        def initialize(represented)
          super(represented)
        end

        property :linked_resources,
                 as: :_links,
                 exec_context: :decorator

        property :lock_version,
                 render_nil: true,
                 getter: ->(*) {
                   lock_version.to_i
                 }
        property :subject,
                 render_nil: true

        property :done_ratio,
                 as: :percentageDone,
                 render_nil: true,
                 if: ->(*) { Setting.work_package_done_ratio == 'field' }

        property :estimated_hours,
                 as: :estimatedTime,
                 exec_context: :decorator,
                 render_nil: true

        property :description,
                 exec_context: :decorator,
                 render_nil: true

        property :start_date,
                 exec_context: :decorator,
                 render_nil: true,
                 if: ->(*) { !represented.milestone? }

        property :due_date,
                 exec_context: :decorator,
                 render_nil: true,
                 if: ->(*) { !represented.milestone? }

        property :date,
                 exec_context: :decorator,
                 render_nil: true,
                 if: ->(represented:, **) { represented.milestone? }

        property :created_at,
                 getter: ->(*) { nil }, render_nil: false

        property :updated_at,
                 getter: ->(*) { nil }, render_nil: false

        def linked_resources
          work_package_attribute_links_representer represented
        end

        def linked_resources=(value)
          representer = work_package_attribute_links_representer represented
          representer.from_json(value.to_json)
        end

        def estimated_hours
          datetime_formatter.format_duration_from_hours(represented.estimated_hours,
                                                        allow_nil: true)
        end

        def estimated_hours=(value)
          represented.estimated_hours = datetime_formatter
                                        .parse_duration_to_hours(value,
                                                                 'estimated_hours',
                                                                 allow_nil: true)
        end

        def description
          API::Decorators::Formattable.new(represented.description, object: represented)
        end

        def description=(value)
          represented.description = value['raw']
        end

        def start_date
          datetime_formatter.format_date(represented.start_date, allow_nil: true)
        end

        def start_date=(value)
          represented.start_date = datetime_formatter.parse_date(value,
                                                                 'startDate',
                                                                 allow_nil: true)
        end

        def due_date
          datetime_formatter.format_date(represented.due_date, allow_nil: true)
        end

        def due_date=(value)
          represented.due_date = datetime_formatter.parse_date(value,
                                                               'dueDate',
                                                               allow_nil: true)
        end

        def date=(value)
          new_date = datetime_formatter.parse_date(value,
                                                   'date',
                                                   allow_nil: true)

          represented.due_date = represented.start_date = new_date
        end

        def date
          datetime_formatter.format_date(represented.due_date, allow_nil: true)
        end

        def datetime_formatter
          API::V3::Utilities::DateTimeFormatter
        end

        def work_package_attribute_links_representer(represented)
          ::API::V3::WorkPackages::WorkPackageAttributeLinksRepresenter.create represented
        end
      end
    end
  end
end
