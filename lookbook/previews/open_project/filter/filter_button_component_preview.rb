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

module OpenProject
  module Filter
    # @logical_path OpenProject/Filter
    class FilterButtonComponentPreview < Lookbook::Preview
      def default
        @query = ProjectQuery.new
        render(::Filter::FilterButtonComponent.new(query: @query))
      end

      # @label With toggable filter section
      # There is a stimulus controller, which can toggle the visibility of an FilterComponent with the help of a FilterButton.
      # Just register the controller in a container around both elements.
      # Unfortunately, stimulus controllers do not work in our lookbook as of now, so you will see no effect.
      def filter_section_toggle
        @query = ProjectQuery.new
        render_with_template(locals: { query: @query })
      end
    end
  end
end
