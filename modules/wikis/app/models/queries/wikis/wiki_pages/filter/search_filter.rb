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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Queries
  module Wikis
    module WikiPages
      module Filter
        class SearchFilter < Filters::Base
          self.model = ::WikiPage

          def type = :search

          def human_name = I18n.t("label_search")

          def where
            values.first.split(/\s+/).map do |token|
              condition = searchable_columns.map do |column|
                ::Queries::Operators::Contains.sql_for_field([token], ::WikiPage.table_name, column)
              end.join(" OR ")

              "(#{condition})"
            end.join(" AND ")
          end

          private

          def searchable_columns
            %w[title text]
          end
        end
      end
    end
  end
end
