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
  class ParseResourceParamsService
    attr_accessor :model,
                  :representer,
                  :current_user

    def initialize(user, model: nil, representer: nil)
      self.current_user = user
      self.model = model

      self.representer = if !representer && model
                           deduce_representer(model)
                         elsif representer
                           representer
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

      ServiceResult.new(success: true,
                        result: parsed)
    end

    private

    def deduce_representer(_model)
      raise NotImplementedError
    end

    def parsing_representer
      representer
        .new(struct, current_user: current_user)
    end

    def parse_attributes(request_body)
      parsing_representer
        .from_hash(request_body)
        .to_h
    end

    def struct
      OpenStruct.new
    end
  end
end
