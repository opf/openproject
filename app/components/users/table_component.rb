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

module Users
  class TableComponent < ::TableComponent
    columns :login, :firstname, :lastname, :mail, :admin, :created_at, :last_login_on
    options :current_user

    def before_render
      @user_query = model if model.is_a?(Queries::BaseQuery)
      super
    end

    def columns
      @columns ||= if @user_query&.selects&.any?
                     @user_query.selects
                   else
                     super
                   end
    end

    def initial_sort
      %i[id asc]
    end

    def headers
      columns.map do |column|
        key = column.respond_to?(:attribute) ? column.attribute.to_s : column.to_s
        [key, header_options(column)]
      end
    end

    def header_options(column)
      attr = column.respond_to?(:attribute) ? column.attribute : column
      caption = column.respond_to?(:caption) ? column.caption : User.human_attribute_name(attr)
      options = { caption: }
      options[:default_order] = "desc" if desc_by_default.include?(attr)
      options
    end

    def desc_by_default
      %i[admin created_at last_login_on]
    end
  end
end
