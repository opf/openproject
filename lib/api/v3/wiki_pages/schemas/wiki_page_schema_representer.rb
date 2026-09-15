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
    module WikiPages
      module Schemas
        class WikiPageSchemaRepresenter < ::API::Decorators::SchemaRepresenter
          schema :id,
                 type: "Integer"

          schema :title,
                 type: "String",
                 min_length: 1

          schema :slug,
                 type: "String",
                 writable: false

          schema :text,
                 type: "Formattable",
                 required: false

          schema :lock_version,
                 type: "Integer",
                 required: true

          schema :version,
                 type: "Integer",
                 writable: false,
                 required: false

          schema :protected,
                 type: "Boolean",
                 required: false

          schema :created_at,
                 type: "DateTime"

          schema :updated_at,
                 type: "DateTime"

          schema_with_allowed_link :project,
                                   has_default: false,
                                   required: true,
                                   href_callback: ->(*) { nil }

          schema_with_allowed_link :parent,
                                   type: "WikiPage",
                                   href_callback: ->(*) { nil },
                                   required: false

          schema_with_allowed_link :author,
                                   type: "User",
                                   writable: false,
                                   required: false,
                                   href_callback: ->(*) { nil }

          def self.represented_class
            WikiPage
          end
        end
      end
    end
  end
end
