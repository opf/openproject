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

RSpec.describe WorkPackages::Import::CSV::Template do
  subject(:template) { described_class.call(project:, user:) }

  shared_let(:type) { create(:type_task, name: "Task") }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:status) { create(:default_status, name: "New") }
  shared_let(:priority) { create(:default_priority, name: "Normal") }
  shared_let(:category) { create(:category, project:, name: "Backend") }
  shared_let(:version) { create(:version, project:, name: "Sprint 12") }
  shared_let(:user) do
    create(:user,
           mail: "alice@example.com",
           member_with_permissions: { project => %i[view_work_packages work_package_assigned] })
  end

  let(:rows) { CSV.parse(template.delete_prefix("﻿")) }

  it "starts with a byte order mark, so Excel reads it as UTF-8" do
    expect(template).to start_with("﻿")
  end

  it "carries every column of the contract, in the order the contract lists them" do
    expect(rows.first).to eq(["Subject", "Description", "Type", "Status", "Priority", "Category",
                              "Version", "Assignee", "Accountable", "Author", "Start date",
                              "Finish date", "Work", "Remaining work", "% Complete",
                              "Created on", "Updated on"])
  end

  it "gives two example rows" do
    expect(rows.size).to eq(3)
  end

  it "takes the example text from the locale" do
    expect(rows[1][0]).to eq("Write the documentation")
    expect(rows[2][0]).to eq("Fix the login error")
  end

  context "in another language" do
    include_context "with locale for testing"

    let(:translations) do
      { activerecord: { attributes: { work_package: { subject: "Translated header" } } },
        work_packages: { import: { csv: { template: { examples: { one: { subject: "Translated subject" } } } } } } }
    end

    it "follows the locale rather than baking the text in" do
      expect(rows.first.first).to eq("Translated header")
      expect(rows[1][0]).to eq("Translated subject")
    end
  end

  it "fills every cell of every example" do
    expect(rows[1]).to all(be_present)
    expect(rows[2]).to all(be_present)
  end

  it "names a type the project actually has" do
    expect(rows[1][2]).to eq("Task")
    expect(rows[2][2]).to eq("Task")
  end

  it "leaves the type blank rather than inventing one when the project has none" do
    expect(bare_rows[1][2]).to be_nil
  end

  it "names the default status and priority" do
    expect(rows[1][3..4]).to eq(["New", "Normal"])
    expect(rows[2][3..4]).to eq(["New", "Normal"])
  end

  it "falls back to an existing status and priority where neither is marked as the default" do
    Status.update_all(is_default: false)
    IssuePriority.update_all(is_default: false)

    expect(rows[1][3..4]).to eq(["New", "Normal"])
  end

  it "names a category and a version the project actually has" do
    expect(rows[1][5..6]).to eq(["Backend", "Sprint 12"])
    expect(rows[2][5..6]).to eq(["Backend", "Sprint 12"])
  end

  it "leaves the category and the version blank rather than inventing ones the project has not" do
    expect(bare_rows[1][5..6]).to eq([nil, nil])
  end

  it "names the user downloading it, by the address they sign in with" do
    expect(rows[1][7..9]).to eq(["alice@example.com"] * 3)
    expect(rows[2][7..9]).to eq(["alice@example.com"] * 3)
  end

  it "names someone the project allows to be assigned where the downloader is not" do
    outsider = create(:user, mail: "outsider@example.com")
    cells = CSV.parse(described_class.call(project:, user: outsider).delete_prefix("﻿"))[1]

    expect(cells[7..8]).to eq(["alice@example.com"] * 2)
    expect(cells[9]).to eq("outsider@example.com")
  end

  it "gives Work and Remaining work that agree with the % Complete beside them" do
    expect(rows[1][12..14]).to eq(%w[8 8 0])
    expect(rows[2][12..14]).to eq(%w[3.5 1.75 50])
  end

  it "dates the examples from today, so the template does not go stale" do
    expect(Date.iso8601(rows[1][10])).to eq(Date.current + 1)
    expect(Date.iso8601(rows[1][11])).to eq(Date.current + 5)
  end

  it "timestamps the examples in the past, created on before updated on" do
    created_on, updated_on = rows[1][15..16].map { |cell| Time.iso8601(cell) }

    expect(created_on).to be < updated_on
    expect(updated_on).to be < Time.current
  end

  context "when progress is calculated from the status" do
    before { allow(WorkPackage).to receive(:status_based_mode?).and_return(true) }

    it "leaves out the columns the parser would reject, which the status derives" do
      expect(rows.first).not_to include("% Complete")
      expect(rows.first).not_to include("Remaining work")
    end

    it "still parses back through the importer's own parser" do
      expect(parse_back(template)).to be_success
    end
  end

  it "parses back through the importer's own parser" do
    expect(parse_back(template)).to be_success
  end

  it "maps every cell it filled back to a value the importer resolves" do
    rows = parse_back(template).result
    mapper = WorkPackages::Import::CSV::RowMapper.new(project:, rows:)

    expect(rows.map { |row| mapper.call(row) }).to all(be_success)
  end

  def parse_back(body)
    file = Tempfile.new(["template", ".csv"])
    file.write(body)
    file.close

    WorkPackages::Import::CSV::Parser.call(file.path)
  end

  def bare_rows
    bare = create(:project, no_types: true)

    CSV.parse(described_class.call(project: bare, user:).delete_prefix("﻿"))
  end
end
