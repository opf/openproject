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

module WorkPackageTypes
  module Types
    class TableComponent < ::TableComponent
      columns :name, :color, :workflow_warning, :default, :milestone, :sort

      def headers
        [
          [:name, { caption: Type.human_attribute_name(:name) }],
          [:color, { caption: Type.human_attribute_name(:color) }],
          [:workflow_warning, { caption: I18n.t(:label_workflow) }],
          [:default, { caption: I18n.t(:label_active_in_new_projects) }],
          [:milestone, { caption: Type.human_attribute_name(:is_milestone) }],
          [:sort, { caption: I18n.t(:button_sort) }]
        ]
      end

      def header_options(name)
        headers_hash = headers.to_h
        headers_hash[name.to_sym] || { caption: name.to_s }
      end

      def mobile_title
        I18n.t(:label_type_plural)
      end

      def sortable?
        false
      end
    end
  end
end
