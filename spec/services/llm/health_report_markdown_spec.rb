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

RSpec.describe Llm::HealthReportMarkdown do
  subject(:document) { described_class.new(connection, report).to_s }

  let(:connection) { create(:llm_connection, base_url: "https://example.com/v1") }
  let(:hostile) { "qwen\n# Owned ![pixel](https://attacker.invalid/p) | <b>x</b>" }
  let(:report) do
    result = HealthReport::Result.warning(:default_chat_model, :default_model_missing, { "model" => hostile })
    HealthReport.new(subject: connection,
                     created_at: Time.zone.parse("2026-10-10 08:00"),
                     results: [HealthReport::ResultGroup.new(key: :models, results: [result])])
  end

  # A model identifier comes from the server, and the document is pasted into
  # support tickets that render Markdown. Inside a code span nothing is rendered.
  it "puts a server-supplied value into a code span, on one line" do
    expect(document).to include("`qwen # Owned ![pixel](https://attacker.invalid/p) | <b>x</b>`")
    expect(document).not_to include("\n# Owned")
  end

  context "with a value that is a bare link with emphasis" do
    let(:hostile) { "https://attacker.invalid/support ~~healthy~~" }

    it "keeps it literal as well" do
      expect(document).to include("`https://attacker.invalid/support ~~healthy~~`")
    end
  end

  context "with a value that tries to close the code span" do
    let(:hostile) { "qwen` ![pixel](https://attacker.invalid/p) `" }

    it "drops the backticks" do
      expect(document).to include("`qwen ![pixel](https://attacker.invalid/p)`")
    end
  end

  it "puts the settings into code spans too" do
    expect(document).to include("| base_url | `https://example.com/v1` |")
  end
end
