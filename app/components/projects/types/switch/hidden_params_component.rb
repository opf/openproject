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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects
  module Types
    module Switch
      # The parameters a page needs carried through the switch's steps, such as its selection.
      class HiddenParamsComponent < ApplicationComponent
        def initialize(params:)
          super()

          @params = params
        end

        def call
          safe_join(
            @params.flat_map do |name, value|
              if value.is_a?(Array)
                value.map { hidden_field_tag("#{name}[]", it, id: nil) }
              else
                [hidden_field_tag(name, value, id: nil)]
              end
            end
          )
        end
      end
    end
  end
end
