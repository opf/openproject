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

RSpec.describe "project menu" do
  let(:current_user) { create(:admin) }
  let!(:project) { create(:valid_project, identifier: "ponyo", name: "Ponyo") }

  before do
    allow(User).to receive(:current).and_return current_user
    # remove filters that might be left overs from former specs
    CostQuery::Cache.reset!
  end

  ##
  # Depending on the current page the link to the cost reports was broken.
  # This seems to be due to a peculiarity of the rails routing where
  # `url_for controller: :foo` would return a link relative to the controller
  # handling the current request path if the controller was routed to via a
  # namespaced route.
  #
  # Example:
  #
  # `url_for controller: 'cost_reports'` will yield different results ...
  #
  # when on `/projects/ponyo/work_packages`: `/projects/ponyo/cost_reports` (correct)
  # when on `/projects/ponyo/calendar`: `/work_packages/cost_reports?project_id=ponyo`
  #
  # This is only relevant for project menu entries, not global ones (`project_id` param is nil)*.
  # Meaning that you have to make sure to force the absolute URL in a project menu entry
  # by specificying the controller as e.g. '/cost_reports' instead of just 'cost_reports'.
  #
  # Refer to `engine.rb` to see where the menu entries are declared.
  #
  # * May apply to routes used with parameters in general.
  describe "#18788 (cost reports not found (404)) regression test" do
    describe "link to project cost reports" do
      shared_examples "it leads to the project costs reports" do
        before do
          visit current_path
        end

        it "leads to cost reports" do
          find("#main-menu #{test_selector('op-menu--item-action')}", text: "Time and costs").click

          expect(page).to have_current_path("/projects/ponyo/cost_reports")
        end
      end

      context "when on the project's activity page" do
        let(:current_path) { "/projects/ponyo/activity" }

        it_behaves_like "it leads to the project costs reports"
      end

      context "when on the project's calendars" do
        let(:current_path) { "/projects/ponyo/calendars" }

        it_behaves_like "it leads to the project costs reports"
      end
    end

    describe "link to global cost reports" do
      shared_examples "it leads to the cost reports" do
        before do
          visit current_path
        end

        it "leads to cost reports" do
          # doing what no human can - click on invisible items.
          # This way, we avoid having to use selenium and by that increase stability.
          find("#main-menu #{test_selector('op-menu--item-action')}", text: "Time and costs").click

          # to make sure we're not seeing the project cost reports:
          expect(page).to have_no_text("Ponyo")
        end
      end

      context "when on the project's activity page" do
        let(:current_path) { "/projects/ponyo/activity" }

        it_behaves_like "it leads to the cost reports"
      end

      context "when on the project's calendar" do
        let(:current_path) { "/projects/ponyo/calendars" }

        it_behaves_like "it leads to the cost reports"
      end
    end
  end
end
