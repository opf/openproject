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
    module Users
      module Schemas
        class UserSchemaRepresenter < ::API::Decorators::SchemaRepresenter
          extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass
          custom_field_injector type: :schema_representer

          schema :id,
                 type: "Integer"

          schema :login,
                 type: "String",
                 min_length: 1,
                 max_length: 255

          schema :admin,
                 type: "Boolean",
                 required: false

          schema :email,
                 type: "String",
                 min_length: 1,
                 max_length: 255

          schema :name,
                 type: "String",
                 required: false,
                 writable: false

          schema :firstname,
                 as: :firstName,
                 type: "String",
                 min_length: 1,
                 max_length: 255

          schema :lastname,
                 as: :lastName,
                 type: "String",
                 min_length: 1,
                 max_length: 255

          schema :avatar,
                 type: "String",
                 writable: false,
                 required: false

          schema :status,
                 type: "String",
                 required: false

          schema :identity_url,
                 type: "String",
                 required: false

          schema :language,
                 type: "String",
                 required: false

          schema :password,
                 type: "Password",
                 required: false

          schema :created_at,
                 type: "DateTime"

          schema :updated_at,
                 type: "DateTime"

          def self.represented_class
            ::User
          end
        end
      end
    end
  end
end
