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

require "spec_helper"

RSpec.describe "Examples documented in separate files" do # rubocop:disable RSpec/DescribeClass
  examples_map = {} # rubocop:disable RSpec/LeakyLocalVariable
  Dir[
    Rails.root.join("docs/api/apiv3/paths/*.yml").to_s
  ].each do |f|
    yaml = YAML.load_file(f)
    yaml.each_value do |method_doc|
      request = method_doc.dig("requestBody", "content", "application/json")
      responses = method_doc.fetch("responses", {}).values.filter_map { |resp| resp.dig("content", "application/hal+json") }
      (responses + [request]).compact.each do |content_doc|
        example_files = content_doc.fetch("examples", {}).values.filter_map { |e| e["$ref"] }
        example_matches = example_files.filter_map do |example_file|
          %r{\.\./components/examples/([\w-]+).yml}.match(example_file)
        end
        schema_match = %r{\.\./components/schemas/([\w-]+)\.yml}.match(content_doc.dig("schema", "$ref"))
        next if schema_match.nil?

        schema_name = schema_match[1]
        examples_map[schema_name] ||= []
        examples_map[schema_name] = (examples_map[schema_name] + example_matches.map { |m| m[1] }).uniq
      end
    end
  end

  # List of [schema, example]-pairs that shall be skipped
  skipped_combinations = { # rubocop:disable RSpec/LeakyLocalVariable
    %w[grid_write_model grid-simple-patch-model] => "schema needs to be split into write and read schema",
    %w[portfolio_model portfolio_body] => "schema needs to be split into write and read schema",
    %w[program_model program_body] => "schema needs to be split into write and read schema",
    %w[project_model project_body] => "schema needs to be split into write and read schema",
    %w[relation_write_model relation_update_request] => "schema is intended for create request... split or weaken schema?"
  }

  it "auto-discovers schemas and examples [SELF-TEST]" do
    # heuristic self-test, when writing this spec there were 59 examples to be discovered. This number should
    # grow over time, but usually not get smaller (unless doc restructuring breaks the auto-discovery)
    expect(examples_map.values.sum(&:size)).to be > 55
  end

  examples_map.each do |schema_name, example_names|
    describe schema_name do
      let(:schema) { JsonSchemaLoader.new.load(schema_name) }

      example_names.each do |example_name|
        it "is implemented by #{example_name}" do
          skip(skipped_combinations.fetch([schema_name, example_name])) if skipped_combinations.key?([schema_name, example_name])

          example = YAML.load_file(Rails.root.join("docs/api/apiv3/components/examples/#{example_name}.yml"))
                        .deep_symbolize_keys
                        .fetch(:value)

          # TODO: It would be nice to just skip the abbreviated element from "required" validations, instead of skipping the
          #       entire validation of the schema
          if all_keys(example).exclude?(:_abbreviated)
            expect(example.to_json).to match_json_schema(schema)
          end
        end
      end
    end
  end

  def all_keys(object)
    return object.flat_map { |e| all_keys(e) } if object.is_a?(Array)
    return [] unless object.is_a?(Hash)

    object.flat_map { |k, v| [k, all_keys(v)].flatten }
  end
end
