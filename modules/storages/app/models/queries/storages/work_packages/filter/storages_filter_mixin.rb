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

module Queries::Storages::WorkPackages::Filter::StoragesFilterMixin
  def type
    :list
  end

  def human_name
    ::Storages::Storage.human_attribute_name(name)
  end

  # Returns the model class for which the filter will apply.
  #
  # Used in the where and joins clauses.
  def filter_model
    raise NotImplementedError
  end

  # Returns the column name for which the filter will apply.
  #
  # Used in the where clause.
  def filter_column
    raise NotImplementedError
  end

  def allowed_values
    # Allow all input values that are given to the filter.
    # If no result is found, an empty collection is returned.
    values.map { |value| [nil, value] }
  end

  def where
    <<-SQL.squish
      #{::Queries::Operators::Equals.sql_for_field(where_values, filter_model.table_name, filter_column)}
      AND work_packages.project_id IN (#{Project.allowed_to(User.current, permission).select(:id).to_sql})
      #{additional_where_condition}
    SQL
  end

  def where_values
    values
  end

  def additional_where_condition
    ""
  end

  def joins
    filter_model.table_name.to_sym
  end

  def unescape_hosts(hosts)
    hosts.map { |host| CGI.unescape(host).gsub(/\/+$/, "") }
  end

  # Host values are valid with or without a trailing slash and they match either case.
  # Example: If the host is either "https://example.com" or "https://example.com/",
  # both of the following values are valid:
  # - "https://example.com"
  # - "https://example.com/"
  def prepare_host_values(hosts)
    nested_host_values = hosts.map do |host|
      host_value = CGI.unescape(host)
      possible_host_values = [host_value]
      possible_host_values << "#{host_value}/" unless host_value.ends_with?("/")
      possible_host_values << host_value.chomp("/") if host_value.ends_with?("/")
      possible_host_values
    end

    nested_host_values.flatten
  end
end
