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

require "spec_helper"

RSpec.describe "Examples embedded in APIv3 schemas" do # rubocop:disable RSpec/DescribeClass
  # rubocop:disable-next RSpec/LeakyLocalVariable
  schema_names = Dir[
    Rails.root.join("docs/api/apiv3/components/schemas/*").to_s
  ].map { |f| File.basename(f).split(".", 2).first }.grep(/model$/)

  it "auto-discovers schemas [SELF-TEST]" do
    # heuristic self-test, when writing this spec there were 159 schemas to be discovered. This number should
    # grow over time, but usually not get smaller (unless doc restructuring breaks the auto-discovery)
    expect(schema_names.size).to be > 150
  end

  schema_names.each do |schema_name|
    it "has no schema errors in #{schema_name}" do
      schema = JsonSchemaLoader.new.load(schema_name)
      example = schema[:example]

      # TODO: It would be nice to just skip the abbreviated element from "required" validations, instead of skipping the
      #       entire validation of the schema
      if example && all_keys(example).exclude?(:_abbreviated)
        expect(example.to_json).to match_json_schema(schema)
      end
    end
  end

  def all_keys(object)
    return object.flat_map { |e| all_keys(e) } if object.is_a?(Array)
    return [] unless object.is_a?(Hash)

    object.flat_map { |k, v| [k, all_keys(v)].flatten }
  end
end
