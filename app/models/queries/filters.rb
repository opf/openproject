#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Queries::Filters
  STRATEGIES = {
    list: Queries::Filters::Strategies::List,
    list_all: Queries::Filters::Strategies::ListAll,
    list_optional: Queries::Filters::Strategies::ListOptional,
    integer: Queries::Filters::Strategies::Integer,
    date: Queries::Filters::Strategies::Date,
    datetime_past: Queries::Filters::Strategies::DateTimePast,
    string: Queries::Filters::Strategies::String,
    text: Queries::Filters::Strategies::Text,
    search: Queries::Filters::Strategies::Search,
    float: Queries::Filters::Strategies::Float,
    inexistent: Queries::Filters::Strategies::Inexistent,
    empty_value: Queries::Filters::Strategies::EmptyValue
  }.freeze

  ##
  # Wrapper class for invalid filters being created
  class InvalidError < StandardError; end
  class MissingError < StandardError; end
end
