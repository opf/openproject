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

require "spec_helper"

RSpec.describe API::V3::WorkPackages::WorkPackageRepresenter do
  include_context "eager loaded work package representer"

  let(:current_user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:budget) { build_stubbed(:budget, project:) }
  let(:work_package) { build_stubbed(:work_package, project:, budget:) }
  let(:permissions) { %i[view_work_packages] }
  let(:embed_links) { true }
  let(:representer) { described_class.create(work_package, current_user:, embed_links:) }

  subject(:generated) { representer.to_json }

  before do
    login_as current_user

    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project(*permissions, project:)
    end
  end

  describe "budget" do
    context "with the user having the view_budgets permission" do
      let(:permissions) { %i[view_work_packages view_budgets] }

      it_behaves_like "has a titled link" do
        let(:link) { "budget" }
        let(:href) { "/api/v3/budgets/#{budget.id}" }
        let(:title) { budget.subject }
      end

      it "has the budget embedded" do
        expect(subject)
          .to be_json_eql(budget.subject.to_json)
                .at_path("_embedded/budget/subject")
      end

      context "when a non-privileged user's response is cached before the current user reads it" do
        let(:non_privileged_user) { build_stubbed(:user) }
        let(:non_privileged_representer) do
          described_class.create(work_package, current_user: non_privileged_user, embed_links:)
        end

        before do
          non_privileged_representer.to_json
        end

        it "still renders the real budget link for the user having view_budgets (regression AGILE-296)" do
          expect(subject)
            .to be_json_eql("/api/v3/budgets/#{budget.id}".to_json)
                  .at_path("_links/budget/href")

          expect(subject)
            .to be_json_eql(budget.subject.to_json)
                  .at_path("_links/budget/title")
        end
      end
    end

    context "with the user lacking the view_budgets permission" do
      it "renders an undisclosed budget link" do
        expect(subject)
          .to be_json_eql(API::V3::URN_UNDISCLOSED.to_json)
                .at_path("_links/budget/href")

        expect(subject)
          .to be_json_eql(I18n.t(:"api_v3.undisclosed.budget").to_json)
                .at_path("_links/budget/title")
      end

      it "does not disclose the budget subject" do
        expect(subject).not_to include(budget.subject)
      end

      it "has no budget embedded" do
        expect(subject)
          .not_to have_json_path("_embedded/budget")
      end

      it "does not instantiate a budget representer" do
        allow(API::V3::Budgets::BudgetRepresenter).to receive(:create)
        subject
        expect(API::V3::Budgets::BudgetRepresenter).not_to have_received(:create)
      end

      context "when no budget is assigned" do
        let(:budget) { nil }

        it "renders an empty budget link" do
          expect(subject)
            .to be_json_eql(nil.to_json)
                  .at_path("_links/budget/href")

          expect(subject).not_to have_json_path("_links/budget/title")
        end
      end
    end

    context "when a privileged user's response is cached before the current user reads it" do
      let(:privileged_user) { build_stubbed(:admin) }
      let(:privileged_representer) do
        described_class.create(work_package, current_user: privileged_user, embed_links:)
      end

      before do
        privileged_representer.to_json
      end

      it "renders an undisclosed budget link to the user lacking view_budgets (regression AGILE-296)" do
        expect(subject)
          .to be_json_eql(API::V3::URN_UNDISCLOSED.to_json)
                .at_path("_links/budget/href")

        expect(subject).not_to include(budget.subject)
      end
    end
  end
end
