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
require "open3"

RSpec.describe "script/ci/ai_involvement_check.sh", :aggregate_failures do # rubocop:disable RSpec/DescribeClass
  let(:script) { File.expand_path("../../script/ci/ai_involvement_check.sh", __dir__) }

  def run_check(body)
    stdout, stderr, status = Open3.capture3({ "GITHUB_OUTPUT" => "/dev/stdout" }, script, stdin_data: body)
    expect(status).to be_success
    expect(stderr).to be_empty
    stdout.scan(/^(\w+)=(.*)$/).to_h
  end

  def pr_body(section)
    <<~MARKDOWN
      # What are you trying to accomplish?

      Something.

      # AI involvement
      <!-- Self-assess how much AI drove this PR. Uncomment the one line below that fits. -->

      #{section}

      # Merge checklist

      - [ ] Added/updated tests
    MARKDOWN
  end

  it "accepts a level followed by the explanation from the template" do
    body = pr_body("Collaborative – AI generated a substantial part of the code; I reviewed and understand every line.")

    expect(run_check(body)).to eq("status" => "ok", "level" => "Collaborative")
  end

  it "treats None/Assisted as a single level" do
    body = pr_body("None/Assisted – No AI assistance used OR only autocomplete/pasted snippets.")

    expect(run_check(body)).to eq("status" => "ok", "level" => "None/Assisted")
  end

  it "normalises a bare None or Assisted to None/Assisted" do
    expect(run_check(pr_body("None"))).to eq("status" => "ok", "level" => "None/Assisted")
    expect(run_check(pr_body("Assisted"))).to eq("status" => "ok", "level" => "None/Assisted")
  end

  it "ignores levels mentioned in the explanation" do
    body = pr_body("Collaborative – reviewed every line, so not Directed or Autonomous")

    expect(run_check(body)).to eq("status" => "ok", "level" => "Collaborative")
  end

  it "ignores levels that are still commented out, including multi-line comments" do
    body = pr_body(<<~SECTION)
      <!-- None/Assisted – No AI assistance used. -->
      Directed – I specified the requirements and AI implemented most of it.
      <!-- Autonomous – AI worked with little
      supervision. -->
    SECTION

    expect(run_check(body)).to eq("status" => "ok", "level" => "Directed")
  end

  it "accepts CRLF line endings" do
    body = pr_body("Autonomous – AI worked with little supervision.").gsub("\n", "\r\n")

    expect(run_check(body)).to eq("status" => "ok", "level" => "Autonomous")
  end

  it "rejects several levels on separate lines" do
    body = pr_body("Directed – I specified the requirements.\nAutonomous – AI worked with little supervision.")

    expect(run_check(body)).to eq("status" => "multiple_levels", "selected_levels" => "Directed, Autonomous")
  end

  it "rejects several levels on the same line" do
    ["Collaborative / Directed", "Collaborative, Directed", "Collaborative Directed", "Collaborative/Directed – x"]
      .each do |section|
      expect(run_check(pr_body(section)))
        .to eq("status" => "multiple_levels", "selected_levels" => "Collaborative, Directed"), section
    end
  end

  it "rejects a section with all levels still commented out" do
    body = pr_body("<!-- Collaborative – AI generated a substantial part of the code. -->")

    expect(run_check(body)).to eq("status" => "level_missing")
  end

  it "rejects a level that is not at the start of the line" do
    expect(run_check(pr_body("**Collaborative**"))).to eq("status" => "level_missing")
    expect(run_check(pr_body("- Collaborative"))).to eq("status" => "level_missing")
  end

  it "rejects a description without the section" do
    expect(run_check("# What are you trying to accomplish?\n\nSomething.\n")).to eq("status" => "section_missing")
  end
end
