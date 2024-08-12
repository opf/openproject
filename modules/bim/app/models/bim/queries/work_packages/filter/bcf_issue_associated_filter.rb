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

module ::Bim::Queries::WorkPackages::Filter
  class BcfIssueAssociatedFilter < ::Queries::WorkPackages::Filter::WorkPackageFilter
    attr_reader :join_table_suffix

    def type
      :list
    end

    def allowed_values
      [
        [I18n.t(:general_text_yes), OpenProject::Database::DB_VALUE_TRUE],
        [I18n.t(:general_text_no), OpenProject::Database::DB_VALUE_FALSE]
      ]
    end

    def where
      if associated?
        ::Queries::Operators::All.sql_for_field(values, ::Bim::Bcf::Issue.table_name, "id")
      elsif not_associated?
        ::Queries::Operators::None.sql_for_field(values, ::Bim::Bcf::Issue.table_name, "id")
      else
        raise "Unsupported operator or value"
      end
    end

    def includes
      :bcf_issue
    end

    def type_strategy
      @type_strategy ||= ::Queries::Filters::Strategies::BooleanList.new self
    end

    def dependency_class
      "::API::V3::Queries::Schemas::BooleanFilterDependencyRepresenter"
    end

    def available?
      OpenProject::Configuration.bim?
    end

    private

    def associated?
      (operator == "=" && values.first == OpenProject::Database::DB_VALUE_TRUE) ||
        (operator == "!" && values.first == OpenProject::Database::DB_VALUE_FALSE)
    end

    def not_associated?
      (operator == "=" && values.first == OpenProject::Database::DB_VALUE_FALSE) ||
        (operator == "!" && values.first == OpenProject::Database::DB_VALUE_TRUE)
    end
  end
end
