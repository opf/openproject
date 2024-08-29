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
module Queries::Storages::Projects::Filter
  class StorageUrlFilter < ::Queries::Projects::Filters::Base
    include StorageFilterMixin

    private

    def filter_column
      "host"
    end

    def where_values
      prepare_host_values(values)
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
end
