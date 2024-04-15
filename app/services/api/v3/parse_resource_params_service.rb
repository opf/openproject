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
  module V3
    class ParseResourceParamsService < ::API::ParseResourceParamsService
      private

      def deduce_representer(model)
        "API::V3::#{model.to_s.pluralize}::#{model}PayloadRepresenter".constantize
      end

      def parsing_representer
        representer
          .create(struct, current_user:)
      end

      def parse_attributes(request_body)
        super
          .except(:available_custom_fields)
      end

      def struct
        super.tap do |instance|
          if model.respond_to?(:available_custom_fields)
            instance.available_custom_fields = model.available_custom_fields(model.new)
          end
        end
      end
    end
  end
end
