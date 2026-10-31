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

RSpec.describe Projects::PhaseStatusButtonComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:phase) { build_stubbed(:project_phase, **phase_attributes) }
  let(:phase_attributes) { {} }
  let(:user) { build_stubbed(:user) }

  current_user { user }

  subject do
    render_inline(described_class.new(phase:, user:))
    page
  end

  shared_examples "renders nothing" do
    it "renders nothing" do
      subject

      expect(rendered_content).to eq ""
    end
  end

  context "when the user cannot edit project phases" do
    it_behaves_like "renders nothing"

    context "with a status other than the default" do
      let(:phase_attributes) { { status: :completed } }

      it_behaves_like "renders nothing"
    end

    context "when the user can only view project phases" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:view_project_phases, project: phase.project)
        end
      end

      it_behaves_like "renders nothing"
    end

    context "when the user can only edit project attributes, not phases" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:edit_project, project: phase.project)
        end
      end

      it_behaves_like "renders nothing"
    end
  end

  context "when the user can edit project phases" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:edit_project_phases, project: phase.project)
      end
    end

    context "without a status" do
      let(:phase_attributes) { { status: nil } }

      it_behaves_like "renders nothing"
    end

    context "with the default status" do
      it "renders an enabled button for the open status" do
        expect(subject).to have_button "Open", disabled: false
      end

      it "renders a Primer ActionMenu (single variant)" do
        expect(subject).to have_element "action-menu", "data-select-variant": "none"
        expect(subject).to have_test_selector "phase-status-action-menu-#{phase.id}"
      end

      it "renders one menu item per status and marks the current one" do
        subject

        expect(page).to have_menu do
          expect(page).to have_selector :menuitem, count: 3
          expect(page).to have_selector :menuitem, text: "Open", aria: { current: true }
          expect(page).to have_selector :menuitem, text: "In progress"
          expect(page).to have_selector :menuitem, text: "Completed"
        end
      end

      it "links every status to the phase status route using PUT" do
        subject

        expect(page).to have_menu do
          { "Open" => "open", "In progress" => "in_progress", "Completed" => "completed" }.each do |label, code|
            expect(page).to have_selector(:menuitem, text: label) do |link|
              expect(link[:"data-turbo-method"]).to eq "put"
              expect(link[:href]).to eq(project_phase_status_path(phase, status: code))
            end
          end
        end
      end
    end

    context "with an in progress phase" do
      let(:phase_attributes) { { status: :in_progress } }

      it "renders an enabled button for that status" do
        expect(subject).to have_button "In progress", disabled: false
      end

      it "marks only that status as current" do
        subject

        expect(page).to have_menu do
          expect(page).to have_selector :menuitem, text: "In progress", aria: { current: true }
          expect(page).to have_no_selector :menuitem, text: "Open", aria: { current: true }
          expect(page).to have_no_selector :menuitem, text: "Completed", aria: { current: true }
        end
      end
    end

    context "with a completed phase" do
      let(:phase_attributes) { { status: :completed } }

      it "renders an enabled button for that status" do
        expect(subject).to have_button "Completed", disabled: false
      end

      it "marks only that status as current" do
        subject

        expect(page).to have_menu do
          expect(page).to have_selector :menuitem, text: "Completed", aria: { current: true }
          expect(page).to have_no_selector :menuitem, text: "Open", aria: { current: true }
        end
      end
    end
  end
end
