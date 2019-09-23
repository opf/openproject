#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
                 type: 'Integer',
                 visibility: false

          schema :name,
                 type: 'String',
                 visibility: false,
                 min_length: 1,
                 max_length: 255

          schema :identifier,
                 type: 'String',
                 visibility: false,
                 min_length: 1,
                 max_length: 100

          schema :description,
                 type: 'Formattable',
                 visibility: false,
                 required: false

          schema :is_public,
                 as: :public,
                 type: 'Boolean',
                 visibility: false

          schema_with_allowed_string_collection :status,
                                                type: 'String'

          schema :created_at,
                 type: 'DateTime',
                 visibility: false

          schema :updated_at,
                 type: 'DateTime',
                 visibility: false

          def self.represented_class
            ::Project
          end
        end
      end
    end
  end
end
