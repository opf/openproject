#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    class ParseResourceParamsService
      attr_accessor :model,
                    :representer,
                    :current_user

      def initialize(user, model: nil, representer: nil)
        self.current_user = user
        self.model = model

        self.representer = if !representer && model
                             "API::V3::#{model.to_s.pluralize}::#{model}Representer".constantize
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

      def parse_attributes(request_body)
        representer
          .create(struct, current_user: current_user)
          .from_hash(request_body)
          .to_h
          .except(:available_custom_fields)
      end

      def struct
        if model
          OpenStruct.new available_custom_fields: model.new.available_custom_fields
        else
          OpenStruct.new
        end
      end
    end
  end
end
