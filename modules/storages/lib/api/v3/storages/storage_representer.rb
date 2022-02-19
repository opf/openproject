#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

# I understand this is a Roar "representer":
# Also see: For Roar documentation https://github.com/trailblazer/roar
# and the Roar-Rails integration: https://github.com/apotonick/roar-rails
# Roar is a "thin layer on top of": https://github.com/trailblazer/representable
# "Representable maps Ruby objects to documents and back"
# ToDo: What exactly is a representer? I understand it's atrributes plus
# a number of links? These are the ones defined below?
module API
  module V3
    module Storages
      class StorageRepresenter < ::API::Decorators::Single
        # ToDo: LinkedResource is about linking to other objects related to Storages?
        include API::Decorators::LinkedResource
        include API::Decorators::DateProperty

        # ToDo: repeating again the attributes of a Storage?
        property :id

        property :name

        date_time_property :created_at

        date_time_property :updated_at

        # A link back to the specific object ("represented"):
        # ToDo: what is "storage(...)" here?
        link :self do
          {
            href: api_v3_paths.storage(represented.id),
            method: :get
          }
        end

        # There is apparently just a single type supported at the moment...
        # ToDo: So this URL is fake?
        link :type do
          {
            href: "#{::API::V3::URN_PREFIX}storages:nextcloud",
            title: 'Nextcloud'
          }
        end

        link :origin do
          {
            href: represented.host
          }
        end

        def _type
          'Storage'
        end
      end
    end
  end
end
