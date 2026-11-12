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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe Projects::Phases::HoverCardComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:phase) { build_stubbed(:project_phase, :with_gated_definition) }
  let(:gate) { "start" }

  subject { described_class.new(phase:, gate:) }

  before do
    render_inline(subject)
    page.extend TestSelectorFinders
  end

  context "for start" do
    it "renders successfully" do
      page.find_test_selector("phase-gate-hover-card-name", text: phase.start_gate_name)
      page.find_test_selector("phase-gate-hover-card-date", text: phase.start_date.strftime("%m/%d/%Y"))
    end

    context "without a definition" do
      let(:phase) { create(:project_phase) }

      it "renders, but has no content" do
        page.find_test_selector("phase-gate-hover-card-name", text: "")
        page.find_test_selector("phase-gate-hover-card-date", text: "")
      end
    end
  end

  context "for finish" do
    let(:gate) { "finish" }

    it "renders successfully" do
      page.find_test_selector("phase-gate-hover-card-name", text: phase.finish_gate_name)
      page.find_test_selector("phase-gate-hover-card-date", text: phase.finish_date.strftime("%m/%d/%Y"))
    end

    context "without a definition" do
      let(:phase) { create(:project_phase) }

      it "renders, but has no content" do
        page.find_test_selector("phase-gate-hover-card-name", text: "")
        page.find_test_selector("phase-gate-hover-card-date", text: "")
      end
    end
  end
end
