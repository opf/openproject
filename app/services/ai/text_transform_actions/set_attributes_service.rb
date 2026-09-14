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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module AI
  module TextTransformActions
    class SetAttributesService < ::BaseServices::SetAttributes
      private

      def set_attributes(params)
        type_ids = params.delete(:type_ids)

        super

        assign_types(type_ids)
        reset_template_injection
      end

      # The scope select only hides the type picker client-side, so stale
      # type ids may still arrive; the scope decides whether they are kept.
      def assign_types(type_ids)
        if model.specific_work_package_types?
          model.type_ids = Array(type_ids).compact_blank.map(&:to_i) unless type_ids.nil?
        else
          model.types = []
        end
      end

      def reset_template_injection
        model.injects_type_template = false if model.everywhere?
      end
    end
  end
end
