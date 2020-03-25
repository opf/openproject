#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Projects
      module Schemas
        class ProjectSchemaRepresenter < ::API::Decorators::SchemaRepresenter
          extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass
          custom_field_injector type: :schema_representer

          schema :id,
                 type: 'Integer'

          schema :name,
                 type: 'String',
                 min_length: 1,
                 max_length: 255

          schema :identifier,
                 type: 'String',
                 min_length: 1,
                 max_length: 100

          schema :description,
                 type: 'Formattable',
                 required: false

          schema :public,
                 type: 'Boolean'

          schema :active,
                 type: 'Boolean'

          schema :status,
                 type: 'ProjectStatus',
                 name_source: ->(*) { I18n.t('activerecord.attributes.projects/status.code') },
                 required: false,
                 writable: ->(*) { represented.writable?(:status) }

          schema :status_explanation,
                 type: 'Formattable',
                 name_source: ->(*) { I18n.t('activerecord.attributes.projects/status.explanation') },
                 required: false,
                 writable: ->(*) { represented.writable?(:status) }

          schema_with_allowed_link :parent,
                                   type: 'Project',
                                   required: false,
                                   href_callback: ->(*) {
                                     query_props = if represented.model.new_record?
                                                     ''
                                                   else
                                                     "?of=#{represented.model.id}"
                                                   end

                                     api_v3_paths.projects_available_parents + query_props
                                   }

          schema :created_at,
                 type: 'DateTime'

          schema :updated_at,
                 type: 'DateTime'

          def self.represented_class
            ::Project
          end
        end
      end
    end
  end
end
