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

module API
  module V3
    module Principals
      module NotBuiltinElements
        extend ::ActiveSupport::Concern

        included do
          # There is no common representer class for all elements, we thus override the default behaviour
          # of forwarding eager_loading preferences to the element representer
          self.to_eager_load = []
          self.to_preload = []

          collection :elements,
                     getter: ->(*) {
                       represented.map do |model|
                         representer_class = case model
                                             when User
                                               ::API::V3::Users::UserRepresenter
                                             when Group
                                               ::API::V3::Groups::GroupRepresenter
                                             when PlaceholderUser
                                               ::API::V3::PlaceholderUsers::PlaceholderUserRepresenter
                                             else
                                               raise "unsupported type"
                                             end

                         representer_class.create(model, current_user:)
                       end
                     },
                     exec_context: :decorator,
                     embedded: true
        end
      end
    end
  end
end
