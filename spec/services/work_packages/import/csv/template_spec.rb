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
  subject(:template) { described_class.call(project:) }

  shared_let(:type) { create(:type_task, name: "Task") }
  shared_let(:project) { create(:project, types: [type]) }

  let(:rows) { CSV.parse(template.delete_prefix("﻿")) }

  it "starts with a byte order mark, so Excel reads it as UTF-8" do
    expect(template).to start_with("﻿")
  end

  it "carries every column of the contract, in the order the contract lists them" do
    expect(rows.first).to eq(["Subject", "Description", "Type", "Status", "Priority", "Category",
                              "Assignee", "Start date", "Finish date", "Work", "% Complete",
                              "Created on", "Updated on"])
  end

  it "gives two example rows" do
    expect(rows.size).to eq(3)
  end

  it "takes the example text from the locale" do
    expect(rows[1][0]).to eq("Write the documentation")
    expect(rows[2][0]).to eq("Fix the login error")
  end

  it "follows the locale rather than baking the text in" do
    I18n.backend.store_translations(
      :de,
      work_packages: { import: { csv: { template: { examples: { one: { subject: "Doku schreiben" } } } } } }
    )

    translated = I18n.with_locale(:de) { described_class.call(project:) }

    expect(CSV.parse(translated.delete_prefix("﻿"))[1][0]).to eq("Doku schreiben")
  end

  it "names a type the project actually has" do
    expect(rows[1][2]).to eq("Task")
    expect(rows[2][2]).to eq("Task")
  end

  it "leaves the type blank rather than inventing one when the project has none" do
    bare = create(:project, no_types: true)

    expect(CSV.parse(described_class.call(project: bare).delete_prefix("﻿"))[1][2]).to be_nil
  end

  it "dates the examples from today, so the template does not go stale" do
    expect(Date.iso8601(rows[1][7])).to eq(Date.current + 1)
    expect(Date.iso8601(rows[1][8])).to eq(Date.current + 5)
  end

  context "when progress is calculated from the status" do
    before { allow(WorkPackage).to receive(:status_based_mode?).and_return(true) }

    it "leaves out the % Complete column the parser would reject" do
      expect(rows.first).not_to include("% Complete")
    end

    it "still parses back through the importer's own parser" do
      expect(parse_back(template)).to be_success
    end
  end

  it "parses back through the importer's own parser" do
    expect(parse_back(template)).to be_success
  end

  def parse_back(body)
    file = Tempfile.new(["template", ".csv"])
    file.write(body)
    file.close

    WorkPackages::Import::CSV::Parser.call(file.path)
  end
end
