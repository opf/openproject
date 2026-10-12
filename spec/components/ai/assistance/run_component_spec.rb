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

require "rails_helper"

RSpec.describe AI::Assistance::RunComponent, type: :component do
  let(:run) { create(:ai_assistant_run, :finished) }

  subject(:rendered) { render_inline(described_class.new(run:)) }

  context "without findings" do
    it "says that there are no findings" do
      expect(rendered).to have_test_selector("ai-assistance-no-findings")
    end
  end

  context "with findings" do
    before do
      create(:ai_assistant_run_finding, run:, severity: "low", text: "A low finding")
      create(:ai_assistant_run_finding, run:, severity: "high", text: "A high finding")
    end

    it "lists them by severity" do
      texts = rendered.css("[data-test-selector='ai-assistance-finding'] p").map(&:text)

      expect(texts).to eq(["A high finding", "A low finding"])
    end
  end

  context "with inputs that were not checked" do
    before do
      run.add_not_checked(:pull_requests, :no_permission_github)
      run.save!
    end

    it "lists them" do
      expect(rendered).to have_css("[data-test-selector='ai-assistance-not-checked'] li",
                                   text: "Linked GitHub pull requests")
    end
  end
end
