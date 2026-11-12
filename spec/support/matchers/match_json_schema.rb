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

RSpec::Matchers.define :match_json_schema do |expected|
  chain :from_docs do |docs_schema|
    @docs_schema = docs_schema
  end

  match do |actual|
    raise ArgumentError, "Do not pass arguments to match_json_schema, when using .from_docs." if expected && @docs_schema

    schema = @docs_schema ? JsonSchemaLoader.new.load(@docs_schema) : expected

    validator = JSONSchemer.schema(schema)

    @actual = validator.validate(JSON.parse(actual)).map { |result| result.fetch("error") }
    @actual.empty?
  end

  failure_message do |actual|
    actual.join("\n")
  end

  failure_message_when_negated do
    "expected schema to not match, but it did."
  end
end
