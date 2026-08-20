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
    module Types
      class TypeRepresenter < ::API::Decorators::Single
        include API::Decorators::DateProperty
        include ::API::Caching::CachedRepresenter

        cached_representer({})

        self_link

        property :id

        property :name

        property :color,
                 getter: ->(*) { color&.hexcode },
                 render_nil: true
        property :position
        # Kept on the type in the API: the flag moved to the configurations a project applies
        # the type through, and a new project gets the type when any of them carries it.
        # Asked of the collection rather than of #default_variant, which is nil until a type
        # is saved — representers render unsaved and stubbed types too.
        property :is_default,
                 getter: ->(*) { variants.any?(&:enabled_in_new_projects?) }
        property :is_milestone

        date_time_property :created_at
        date_time_property :updated_at

        def _type
          "Type"
        end
      end
    end
  end
end
