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

RSpec.describe WorkPackages::Import::CSV::Parser do
  def fixture(name) = Rails.root.join("spec/fixtures/csv_import", name)

  def with_csv(content, &)
    Tempfile.create(["import", ".csv"], binmode: true) do |file|
      file.write(content)
      file.flush
      yield file.path
    end
  end

  describe "a well-formed file" do
    it "returns a row per line of data, keyed by attribute" do
      result = described_class.call(fixture("work_packages.csv"))

      expect(result).to be_success
      expect(result.result.size).to eq(2)
      expect(result.result.first.values)
        .to include(subject: "Set up the build", type: "Task", estimated_hours: "8")
    end

    it "numbers rows the way a spreadsheet does, with the header as row 1" do
      expect(described_class.call(fixture("work_packages.csv")).result.map(&:number)).to eq([2, 3])
    end

    it "does not care what order the columns are in" do
      with_csv("Type,Subject\nTask,Build it\n") do |path|
        expect(described_class.call(path).result.first.values).to eq(type: "Task", subject: "Build it")
      end
    end

    it "finds the header under a leading blank line, and numbers rows from where it is" do
      with_csv("\nSubject,Type\nA,Task\n") do |path|
        rows = described_class.call(path).result

        expect(rows.map(&:number)).to eq([3])
        expect(rows.first.values[:subject]).to eq("A")
      end
    end

    it "skips blank lines without shifting the numbering of what follows" do
      with_csv("Subject\nFirst\n\nThird\n") do |path|
        rows = described_class.call(path).result

        expect(rows.map(&:number)).to eq([2, 4])
        expect(rows.map { it.values[:subject] }).to eq(%w[First Third])
      end
    end
  end

  describe "encoding" do
    it "tolerates a UTF-8 BOM, which Excel writes" do
      result = described_class.call(fixture("bom.csv"))

      expect(result).to be_success
      expect(result.result.first.values[:subject]).to eq("A")
    end
  end

  describe "line endings" do
    it "reads CRLF, which is what Windows and Excel write" do
      with_csv("Subject,Type\r\nA,Task\r\n") do |path|
        expect(described_class.call(path).result.first.values).to eq(subject: "A", type: "Task")
      end
    end

    it "reads a BOM, CRLF and semicolons together, as Excel on a German locale writes them" do
      with_csv("\xEF\xBB\xBFSubject;Type\r\nA;Task\r\n".b) do |path|
        result = described_class.call(path)

        expect(described_class.new(path).separator).to eq(";")
        expect(result.result.first.values).to eq(subject: "A", type: "Task")
      end
    end
  end

  describe "the separator" do
    it "reads a comma" do
      expect(described_class.new(fixture("work_packages.csv")).separator).to eq(",")
    end

    it "reads a semicolon, which Excel writes on a German locale" do
      expect(described_class.new(fixture("semicolon.csv")).separator).to eq(";")
      expect(described_class.call(fixture("semicolon.csv")).result.size).to eq(2)
    end

    it "reads a tab" do
      with_csv("Subject\tType\nBuild it\tTask\n") do |path|
        expect(described_class.new(path).separator).to eq("\t")
      end
    end

    it "is chosen by which separator makes the headers readable, not by counting them" do
      # One column, whose caption is full of semicolons. Counting would pick ";".
      with_csv(%{"Subject;with;semicolons;inside",Type\nA,Task\n}) do |path|
        expect(described_class.new(path).separator).to eq(",")
      end
    end

    it "falls back to a comma when there is a single column" do
      with_csv("Subject\nBuild it\n") do |path|
        expect(described_class.new(path).separator).to eq(",")
      end
    end
  end

  describe "a header that cannot be used" do
    it "reports the problem and reads no rows" do
      with_csv("Subject,Sprint\nBuild it,12\n") do |path|
        result = described_class.call(path)

        expect(result).to be_failure
        expect(result.result.map(&:header)).to eq(["Sprint"])
      end
    end

    it "rejects % Complete when progress comes from the status", with_settings: { work_package_done_ratio: "status" } do
      with_csv("Subject,% Complete\nBuild it,50\n") do |path|
        result = described_class.call(path)

        expect(result).to be_failure
        expect(result.result.first.message).to start_with("cannot be imported while progress is calculated")
      end
    end

    it "accepts % Complete when progress comes from the field", with_settings: { work_package_done_ratio: "field" } do
      with_csv("Subject,% Complete\nBuild it,50\n") do |path|
        expect(described_class.call(path)).to be_success
      end
    end
  end

  describe "a file with nothing to import" do
    it "reports an empty file" do
      with_csv("") do |path|
        expect(described_class.call(path).result.first.message).to eq("This file is empty.")
      end
    end

    it "reports a header row with nothing under it" do
      with_csv("Subject,Type\n") do |path|
        expect(described_class.call(path).result.first.message)
          .to eq("This file has column headers but no rows underneath them.")
      end
    end
  end

  describe "the row limit" do
    it "refuses a file over the limit", with_settings: { work_package_import_max_rows: 3 } do
      with_csv("Subject\n#{"row\n" * 4}") do |path|
        result = described_class.call(path)

        expect(result).to be_failure
        expect(result.result.first.message).to eq("This file has more rows than can be imported at once. The most is 3.")
      end
    end

    it "accepts a file exactly on the limit", with_settings: { work_package_import_max_rows: 3 } do
      with_csv("Subject\n#{"row\n" * 3}") do |path|
        expect(described_class.call(path)).to be_success
      end
    end
  end

  describe "a file that is not a CSV at all" do
    it "lets MalformedCSVError out, so the caller can tell it from a CSV with problems" do
      expect { described_class.call(fixture("unclosed_quote.csv")) }
        .to raise_error(CSV::MalformedCSVError) { |error| expect(error.line_number).to eq(2) }
    end
  end

  describe "a cell containing a newline" do
    it "reads a header row containing one, rather than raising on it" do
      with_csv(%{"Sub\nject",Type\nA,Task\n}) do |path|
        result = described_class.call(path)

        expect(result).to be_failure
        expect(result.result.map(&:header)).to eq(["Sub\nject"])
      end
    end

    it "keeps the newline in the value" do
      rows = described_class.call(fixture("quoted_newline.csv")).result

      expect(rows.first.values[:description]).to eq("line one\nline two")
    end

    it "numbers the row after it as the spreadsheet does, not as a text editor would" do
      rows = described_class.call(fixture("quoted_newline.csv")).result

      # "B" is on physical line 4, but it is the second row of data, so row 3.
      expect(rows.last.values[:subject]).to eq("B")
      expect(rows.last.number).to eq(3)
    end
  end
end
