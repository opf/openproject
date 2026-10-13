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

RSpec.describe WorkPackages::Import::CSV::HeaderSniffer do
  def fixture(name) = Rails.root.join("spec/fixtures/csv_import", name)

  def with_csv(content)
    Tempfile.create(["import", ".csv"], binmode: true) do |file|
      file.write(content)
      file.flush
      yield file.path
    end
  end

  def sniffing(path) = described_class.call(path, WorkPackages::Import::CSV::HeaderMap.new)

  describe "the separator" do
    it "reads a comma" do
      expect(sniffing(fixture("work_packages.csv")).separator).to eq(",")
    end

    it "reads a semicolon, which Excel writes on a German locale" do
      expect(sniffing(fixture("semicolon.csv")).separator).to eq(";")
    end

    it "reads a tab" do
      with_csv("Subject\tType\tStart date\nBuild it\tTask\t2026-01-05\n") do |path|
        expect(sniffing(path).separator).to eq("\t")
      end
    end

    it "is chosen by which separator makes the headers readable, not by counting them" do
      # One column, whose caption is full of semicolons. Counting would pick ";".
      with_csv(%{"Subject;with;semicolons;inside",Type\nA,Task\n}) do |path|
        expect(sniffing(path).separator).to eq(",")
      end
    end

    it "falls back to a comma when there is a single column" do
      with_csv("Subject\nBuild it\n") do |path|
        expect(sniffing(path).separator).to eq(",")
      end
    end

    it "reads a BOM, CRLF and semicolons together, as Excel on a German locale writes them" do
      with_csv("\xEF\xBB\xBFSubject;Type\r\nA;Task\r\n".b) do |path|
        expect(sniffing(path).separator).to eq(";")
      end
    end
  end

  describe "the header row" do
    it "carries the headers it read, in file order" do
      with_csv("Type,Subject\nTask,Build it\n") do |path|
        expect(sniffing(path).values).to eq(["Type", "Subject"])
      end
    end

    it "drops the trailing blanks a spreadsheet leaves behind" do
      with_csv("Subject,Type,,\nBuild it,Task,,\n") do |path|
        expect(sniffing(path).values).to eq(["Subject", "Type"])
      end
    end

    it "keeps a blank between two headers, which is a column of its own" do
      with_csv("Subject,,Type\nBuild it,,Task\n") do |path|
        expect(sniffing(path).values).to eq(["Subject", nil, "Type"])
      end
    end

    it "sits on the first line of an ordinary file" do
      with_csv("Subject,Type\nBuild it,Task\n") do |path|
        expect(sniffing(path).index).to eq(0)
      end
    end

    it "skips the blank lines a file may start with" do
      with_csv("\n\nSubject,Type\nBuild it,Task\n") do |path|
        expect(sniffing(path).index).to eq(2)
      end
    end

    it "is empty when the file holds nothing" do
      with_csv("") do |path|
        expect(sniffing(path)).to have_attributes(values: [], index: 0)
      end
    end
  end
end
