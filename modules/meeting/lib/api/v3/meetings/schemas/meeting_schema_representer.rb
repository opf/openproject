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

module API
  module V3
    module Meetings
      module Schemas
        class MeetingSchemaRepresenter < ::API::Decorators::SchemaRepresenter
          def initialize(represented, self_link: nil, current_user: nil, form_embedded: false)
            super
          end

          schema :id,
                 type: "Integer"

          schema :title,
                 type: "String",
                 min_length: 1

          schema :location,
                 type: "String",
                 required: false

          schema :duration,
                 type: "Duration"

          schema :start_time,
                 type: "DateTime"

          schema :end_time,
                 type: "DateTime",
                 writable: false

          schema_with_allowed_string_collection :state,
                                                type: "String",
                                                values_callback: -> {
                                                  Meeting.states.keys
                                                }

          schema_with_allowed_string_collection :sharing,
                                                type: "String",
                                                required: false,
                                                values_callback: -> {
                                                  Meeting.sharings.keys
                                                }

          schema :template,
                 type: "Boolean"

          schema :notify,
                 type: "Boolean",
                 required: false

          schema_with_allowed_link :project,
                                   has_default: false,
                                   required: true,
                                   href_callback: ->(*) {}

          schema :lock_version,
                 type: "Integer"

          schema :created_at,
                 type: "DateTime"

          schema :updated_at,
                 type: "DateTime"

          def self.represented_class
            Meeting
          end
        end
      end
    end
  end
end
