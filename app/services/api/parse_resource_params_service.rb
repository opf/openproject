#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
  class ParseResourceParamsService
    attr_accessor :model,
                  :representer,
                  :current_user

    def initialize(user, model: nil, representer: nil)
      self.current_user = user
      self.model = model

      self.representer = if representer
                           representer
                         elsif model
                           deduce_representer(model)
                         else
                           raise 'Representer not defined'
                         end
    end

    def call(request_body)
      parsed = if request_body
                 parse_attributes(request_body)
               else
                 {}
               end

      ServiceResult.success(result: parsed)
    end

    private

    def deduce_representer(_model)
      raise NotImplementedError
    end

    def parsing_representer
      representer
        .new(struct, current_user:)
    end

    def parse_attributes(request_body)
      struct = parsing_representer
               .from_hash(request_body)

      deep_to_h(struct)
        .deep_symbolize_keys
    end

    def struct
      ParserStruct.new
    end

    def deep_to_h(value)
      # Does not yet factor in Arrays. There hasn't been the need to do that, yet.
      case value
      when Hash, ParserStruct
        value.to_h.transform_values do |sub_value|
          deep_to_h(sub_value)
        end
      else
        value
      end
    end
  end
end
