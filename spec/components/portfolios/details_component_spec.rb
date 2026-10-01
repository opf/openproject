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

RSpec.describe Portfolios::DetailsComponent, type: :component do
  include Rails.application.routes.url_helpers
  include FavoriteHelper

  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:reference_time) { Time.zone.local(2025, 2, 1, 12, 0, 0) }
  let(:user) { create(:admin) }
  let(:status_code_a) { "on_track" }
  let(:status_code_b) { "at_risk" }
  let(:active) { true }
  let!(:portfolio) { create(:portfolio, description: "portfolio description", active:) }

  current_user { user }

  subject(:rendered_component) do
    render_component(portfolio:, current_user: user)
  end

  before do
    travel_to(reference_time)

    create(:program, parent: portfolio, status_code: status_code_a).tap do |program_a|
      create(:project, parent: program_a, status_code: status_code_a).tap do |project_a|
        create(:project, parent: project_a, status_code: status_code_b)
      end
    end

    create(:program, parent: portfolio, status_code: status_code_b).tap do |program_b|
      create(:project, parent: program_b, status_code: status_code_b)
      create(:project, parent: program_b, status_code: status_code_a)
    end

    create(:project, parent: portfolio, status_code: status_code_a)

    portfolio.reload

    def portfolio.favorited?; false; end
  end

  after do
    travel_back
  end

  shared_examples "having a description and last update time" do
    it { expect(subject).to have_text(portfolio.description) }

    context "when the portfolio has no description" do
      before do
        allow(portfolio).to receive(:description).and_return(nil)
      end

      it { expect(subject).to have_text("No description provided") }
    end

    describe "#updated_at" do
      before do
        allow(portfolio).to receive(:updated_at).and_return(31.days.ago)
      end

      it "shows when the portfolio was last updated" do
        expect(subject).to have_test_selector("op-portfolios--updated-at", text: "Updated about 1 month ago")
      end
    end
  end

  describe "portfolio" do
    it_behaves_like "having a description and last update time"

    it "renders the title as a link" do
      expect(subject).to have_css(".portfolio-name", text: portfolio.name) do |link|
        expect(link[:href]).to eq(project_overview_path(portfolio))
      end
    end

    it "offers a button to favor the portfolio" do
      expect(subject).to have_test_selector("op-portfolios--favorite-button") do |link|
        expect(link[:href]).to eq(build_favorite_path(portfolio, format: :html))
      end
    end

    describe "displays the number of child programs and projects" do
      it { expect(subject).to have_text("2 programs") }
      it { expect(subject).to have_text("5 projects") }
    end

    describe "portfolio status" do
      it "shows the status button if the status is not set" do
        expect(subject).to have_css("#projects-status-button-component-#{portfolio.id}", text: "Not set")
      end

      it "shows the status button if the status is set" do
        portfolio.status_code = "on_track"
        expect(subject).to have_css("#projects-status-button-component-#{portfolio.id}", text: "On track")
      end
    end

    describe "sub-item status" do
      context "when none of the sub-items has a status" do
        let(:status_code_a) { nil }
        let(:status_code_b) { nil }

        it "renders an empty status bar" do
          expect(subject).to have_test_selector("op-portfolios--sub-status-bar")
          expect(subject).to have_test_selector("op-portfolios--status-not_set")
          expect(subject).not_to have_test_selector("op-portfolios--status-#{status_code_a}")
          expect(subject).not_to have_test_selector("op-portfolios--status-#{status_code_b}")
        end
      end

      context "when some of the sub-items have a status set" do
        let(:status_code_b) { nil }

        it "renders a progress bar detailing the status of child programs and projects" do
          expect(subject).to have_test_selector("op-portfolios--sub-status-bar")

          expect(subject).to have_test_selector("op-portfolios--status-#{status_code_a}")
          expect(subject).not_to have_test_selector("op-portfolios--status-#{status_code_b}")
          expect(subject).to have_test_selector("op-portfolios--status-not_set")
        end
      end

      context "when all of the sub-items have a status set" do
        it "renders a progress bar detailing the status of child programs and projects" do
          expect(subject).to have_test_selector("op-portfolios--sub-status-bar")

          expect(subject).to have_test_selector("op-portfolios--status-#{status_code_a}")
          expect(subject).to have_test_selector("op-portfolios--status-#{status_code_b}")
          expect(subject).not_to have_test_selector("op-portfolios--status-not_set")
        end
      end
    end
  end

  describe "archived portfolio" do
    let(:active) { false }

    it_behaves_like "having a description and last update time"

    it { expect(subject).to have_no_text("2 programs") }
    it { expect(subject).to have_no_text("5 projects") }

    it "renders the title as text" do
      expect(subject).to have_no_css(".portfolio-name.Link")
      expect(subject).to have_css(".portfolio-name", text: "#{portfolio.name} (Archived)")
    end

    it "has a button to favor the portfolio" do
      expect(subject).not_to have_test_selector("op-portfolios--favorite-button")
    end

    it "has no status button" do
      expect(subject).to have_no_css("#projects-status-button-component-#{portfolio.id}")
    end

    it "has no sub-item status" do
      expect(subject).not_to have_test_selector("op-portfolios--sub-status-bar")
    end
  end
end
