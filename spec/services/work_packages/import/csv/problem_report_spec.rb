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

RSpec.describe WorkPackages::Import::CSV::ProblemReport do
  def report(payload) = described_class.call(payload:)

  def rows(payload) = CSV.parse(report(payload).delete_prefix("﻿"))

  describe "a run whose rows were rejected" do
    let(:payload) do
      {
        "problems" => [
          { "row" => 2, "attribute" => "type", "value" => "Epic", "message" => "does not exist in this project." }
        ],
        "available" => { "type" => %w[Task Milestone] }
      }
    end

    it "names the line, the column and what was accepted instead" do
      expect(rows(payload))
        .to eq([%w[Line Column Value Problem Available],
                ["2", "Type", "Epic", "does not exist in this project.", "Task, Milestone"]])
    end

    it "opens with a byte order mark, so a spreadsheet reads it as UTF-8" do
      expect(report(payload)).to start_with("﻿")
    end

    it "carries every problem, including the ones the page does not show" do
      problems = Array.new(WorkPackages::Import::CSV::ReportComponent::SHOWN_PROBLEMS + 40) do |index|
        { "row" => index + 2, "attribute" => "subject", "value" => "", "message" => "can't be blank." }
      end

      expect(rows(payload.merge("problems" => problems)).size).to eq(problems.size + 1)
    end
  end

  describe "a run whose file was rejected" do
    let(:payload) do
      { "column_problems" => [{ "column" => "C", "header" => "Sprint", "message" => "cannot be imported." }] }
    end

    it "reports the columns instead of the lines" do
      expect(rows(payload))
        .to eq([%w[Column Header Problem], ["C", "Sprint", "cannot be imported."]])
    end

    it "carries every column, including the ones the page does not show" do
      problems = Array.new(WorkPackages::Import::CSV::ReportComponent::SHOWN_PROBLEMS + 12) do |index|
        { "column" => "C#{index}", "header" => "Sprint #{index}", "message" => "cannot be imported." }
      end

      expect(rows(payload.merge("column_problems" => problems)).size).to eq(problems.size + 1)
    end
  end

  describe "a cell a spreadsheet would run as a formula" do
    it "escapes a value carried over from the file" do
      payload = { "problems" => [{ "row" => 2, "value" => "=cmd|'/c calc'!A1", "message" => "does not exist." }] }

      expect(rows(payload).last).to include("'=cmd|'/c calc'!A1")
    end

    it "escapes a header carried over from the file" do
      payload = { "column_problems" => [{ "column" => "C", "header" => "@SUM(1+1)", "message" => "x" }] }

      expect(rows(payload).last).to include("'@SUM(1+1)")
    end

    it "leaves a negative number alone, which is not a formula" do
      payload = { "problems" => [{ "row" => 2, "value" => "-5", "message" => "x" }] }

      expect(rows(payload).last).to include("-5")
    end

    it "does nothing when the instance has turned escaping off", with_settings: { csv_escape_formulas: false } do
      payload = { "problems" => [{ "row" => 2, "value" => "=1+1", "message" => "x" }] }

      expect(rows(payload).last).to include("=1+1")
    end
  end
end
