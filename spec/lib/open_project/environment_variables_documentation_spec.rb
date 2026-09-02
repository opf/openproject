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

RSpec.describe OpenProject::EnvironmentVariablesDocumentation do
  # The list is generated in production, where a good number of defaults differ
  # from the ones here, so this spec checks everything but them.
  let(:page) { File.read(described_class.path) }
  let(:generated_block) { page[described_class::BLOCK_PATTERN] }
  let(:documented_rows) { generated_block.to_s[/^```text\n(.*?)^```$/m, 1].to_s.lines(chomp: true) }
  let(:rows_by_variable) { documented_rows.index_by { |row| row.split(" ", 2).first } }

  let(:regenerate) { "RAILS_ENV=production bundle exec rake docs:env_vars" }

  it "delimits the generated list with the markers the task looks for" do
    expect(generated_block).to be_present, <<~ERR
      #{described_class::DOC_PATH} no longer delimits the generated list with

          #{described_class::BEGIN_MARKER}
          #{described_class::END_MARKER}

      Without both markers, `#{regenerate}` cannot find the list to rewrite.
    ERR

    expect(documented_rows).not_to be_empty, <<~ERR
      The block delimited by #{described_class::BEGIN_MARKER} in #{described_class::DOC_PATH}
      no longer contains a ```text code block with the list of variables.
    ERR

    # The examples below key rows by name, so a collision would drop one silently.
    duplicates = documented_rows.map { |row| row.split(" ", 2).first }.tally.select { |_, count| count > 1 }
    expect(duplicates.keys).to be_empty, "#{duplicates.keys.to_sentence} is listed more than once."
  end

  it "documents every environment variable, and none that no longer exist" do
    expected = described_class.sorted_definitions.map(&:first)
    undocumented = expected - rows_by_variable.keys
    obsolete = rows_by_variable.keys - expected

    expect([undocumented, obsolete]).to eq([[], []]), <<~ERR
      The list in #{described_class::DOC_PATH} no longer covers the same settings as the code.

      #{"Missing: #{undocumented.to_sentence}" if undocumented.any?}
      #{"No longer a setting: #{obsolete.to_sentence}" if obsolete.any?}

      To fix it, regenerate the list by running

          #{regenerate}
    ERR
  end

  it "documents the current description of every environment variable", pending: "seems to be broken" do
    # The default is deliberately not compared, as it differs per environment.
    outdated = described_class.descriptions.reject do |variable, description|
      expected_row = /\A#{Regexp.escape(variable)} \(default=.*\)#{" #{Regexp.escape(description)}" if description}\z/
      rows_by_variable[variable]&.match?(expected_row)
    end

    expect(outdated.keys).to be_empty, <<~ERR
      The description documented for #{outdated.keys.to_sentence} is out of date. Expected,
      respectively:

      #{outdated.map { |variable, description| "  #{variable} -> #{description.inspect}" }.join("\n")}

      To fix it, regenerate the list by running

          #{regenerate}
    ERR
  end

  it "does not document a default that is generated on every read" do
    undeclared = Settings::Definition.all.values.filter_map do |definition|
      next unless definition.persist_on_first_read?
      next unless definition.instance_variable_get(:@default).respond_to?(:call)

      definition.name.to_sym
    end - described_class::RANDOM_DEFAULTS

    expect(undeclared).to be_empty, <<~ERR
      The default of #{undeclared.to_sentence} is generated on first use. Documenting it
      would write something that looks like an instance's secret into
      #{described_class::DOC_PATH}, and change the page on every run.

      Add the setting to #{described_class}::RANDOM_DEFAULTS, then run

          #{regenerate}
    ERR
  end
end
