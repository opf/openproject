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

require "spec_helper"

RSpec.describe WorkPackages::Import::CSV::HeaderMap do
  subject(:map) { described_class.new }

  describe "#resolve" do
    it "resolves every canonical spelling" do
      resolved = described_class::CANONICAL.keys.index_with { |header| map.resolve(header) }

      expect(resolved).to eq(described_class::CANONICAL)
    end

    it "ignores case, surrounding and repeated whitespace" do
      expect(map.resolve("  FINISH    date ")).to eq(:due_date)
    end

    it "ignores a leading apostrophe, which the exporter adds to escape formulas" do
      expect(map.resolve("'% Complete")).to eq(:done_ratio)
    end

    it "maps the captions the user sees, not the column names" do
      expect(map.resolve("Assignee")).to eq(:assigned_to)
      expect(map.resolve("Finish date")).to eq(:due_date)
      expect(map.resolve("Work")).to eq(:estimated_hours)
      expect(map.resolve("Remaining work")).to eq(:remaining_hours)
      expect(map.resolve("Accountable")).to eq(:responsible)
      expect(map.resolve("Author")).to eq(:author)
      expect(map.resolve("Version")).to eq(:version)
    end

    it "does not resolve a column the import has no support for" do
      expect(map.resolve("Parent")).to be_nil
      expect(map.resolve("Duration")).to be_nil
    end

    it "does not resolve an empty header" do
      expect(map.resolve("")).to be_nil
      expect(map.resolve(nil)).to be_nil
    end
  end

  describe "#resolve, in another locale" do
    it "accepts that locale's captions" do
      I18n.with_locale(:de) do
        expect(described_class.new.resolve(WorkPackage.human_attribute_name(:subject))).to eq(:subject)
      end
    end

    it "still accepts the canonical English spellings, so a template file imports anywhere" do
      Redmine::I18n.all_languages.each do |locale|
        I18n.with_locale(locale) do
          resolved = described_class.new
          described_class::CANONICAL.each do |header, attribute|
            expect(resolved.resolve(header)).to eq(attribute),
                                                "#{header.inspect} does not resolve under #{locale}"
          end
        end
      end
    end

    it "builds in every language the product ships" do
      Redmine::I18n.all_languages.each do |locale|
        I18n.with_locale(locale) do
          expect { described_class.new.lookup }.not_to raise_error, "building failed under #{locale}"
        end
      end
    end

    it "drops a caption two attributes share rather than picking one" do
      allow(WorkPackage).to receive(:human_attribute_name).and_call_original
      allow(WorkPackage).to receive(:human_attribute_name).with(:category).and_return("Ambivalent")
      allow(WorkPackage).to receive(:human_attribute_name).with(:priority).and_return("Ambivalent")

      expect(described_class.new.resolve("Ambivalent")).to be_nil
    end

    it "never lets a locale caption take over a canonical spelling" do
      allow(WorkPackage).to receive(:human_attribute_name).and_call_original
      allow(WorkPackage).to receive(:human_attribute_name).with(:type).and_return("Status")

      expect(described_class.new.resolve("Status")).to eq(:status)
    end
  end

  describe "#call" do
    it "maps a header row to column indexes" do
      result = map.call(["Subject", "Type", "Start date"])

      expect(result).to be_success
      expect(result.result).to eq(subject: 0, type: 1, start_date: 2)
    end

    it "does not care what order the columns are in" do
      result = map.call(["Work", "Subject"])

      expect(result.result).to eq(estimated_hours: 0, subject: 1)
    end

    it "reports an unknown column by its spreadsheet letter" do
      result = map.call(["Subject", "Type", "Sprint"])

      expect(result).to be_failure
      expect(result.result.size).to eq(1)

      problem = result.result.first
      expect(problem.column).to eq("C")
      expect(problem.header).to eq("Sprint")
      expect(problem.message).to start_with("cannot be imported")
    end

    it "reports a column the header row left without a name" do
      problem = map.call(["Subject", "", "Type"]).result.first

      expect(problem.column).to eq("B")
      expect(problem.message).to eq("This column has no name. Name it or remove the column.")
    end

    it "suggests the column a typo was probably meant to be" do
      problem = map.call(["Assignde"]).result.first

      expect(problem.message).to eq("cannot be imported. Did you mean Assignee?")
    end

    it "reports the same column twice as a duplicate" do
      problem = map.call(["Subject", "Type", "Subject"]).result.first

      expect(problem.column).to eq("C")
      expect(problem.message).to eq("appears more than once. Keep one of them.")
    end

    it "reports two spellings of one attribute as ambiguous" do
      allow(WorkPackage).to receive(:human_attribute_name).and_call_original
      allow(WorkPackage).to receive(:human_attribute_name).with(:subject).and_return("Thema")

      problem = described_class.new.call(["Subject", "Thema"]).result.first

      expect(problem.header).to eq("Thema")
      expect(problem.message).to eq("and Subject both mean Thema. Keep one of them.")
    end

    it "reports every problem in the row, not just the first" do
      result = map.call(["Sprint", "Subject", "Epic"])

      expect(result.result.map(&:header)).to eq(%w[Sprint Epic])
    end

    it "counts columns beyond Z the way a spreadsheet does" do
      headers = (["Subject"] * 26) + ["Sprint"]

      # 25 duplicates, then the unknown column in position 27
      expect(map.call(headers).result.last.column).to eq("AA")
    end
  end
end
