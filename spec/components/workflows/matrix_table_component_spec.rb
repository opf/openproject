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

RSpec.describe Workflows::MatrixTableComponent, type: :component do
  let(:status_a) { build_stubbed(:status, name: "New") }
  let(:status_b) { build_stubbed(:status, name: "In progress") }
  let(:statuses) { [status_a, status_b] }

  let(:role) { build_stubbed(:project_role) }
  let(:other_role) { build_stubbed(:project_role) }
  let(:roles) { [role] }

  let(:workflows) { [] }
  let(:added_status_ids) { [] }
  let(:readonly) { false }
  let(:tab) { "always" }

  # Stubbed rather than resolved from a persisted type: the matrix is a pure function of
  # these values, and MatrixContext's own resolution rules are specced separately.
  let(:context) do
    instance_double(Workflows::MatrixContext, tab:, statuses:, workflows:, roles:, added_status_ids:, readonly?: readonly)
  end

  subject(:rendered_component) { render_inline(described_class.new(context:)) }

  def transition(old_status:, new_status:, for_role: role)
    build_stubbed(:workflow, role_id: for_role.id, old_status_id: old_status.id, new_status_id: new_status.id)
  end

  # Primer renders array-scheme checkboxes with a trailing [] on the name
  def checkbox_for(old_status:, new_status:)
    rendered_component.at_css("input[name='status[#{old_status.id}][#{new_status.id}][]'][type=checkbox]")
  end

  def indeterminate_marker_for(old_status:, new_status:)
    rendered_component.at_css("input[name='indeterminate_status[#{old_status.id}][#{new_status.id}]'][type=hidden]")
  end

  it "renders a checkbox for every ordered pair of statuses" do
    expect(rendered_component.css("input[type=checkbox]").size).to eq(statuses.size**2)
    expect(checkbox_for(old_status: status_a, new_status: status_b)).to be_present
  end

  it "keys the table by tab so several tabs can coexist in one form" do
    expect(rendered_component.at_css("#workflow_form_always")).to be_present
    expect(rendered_component.at_css("table")["class"]).to include("transitions-always")
  end

  describe "checked state" do
    let(:workflows) { [transition(old_status: status_a, new_status: status_b)] }

    it "checks the pairs the role allows and leaves the others unchecked" do
      expect(checkbox_for(old_status: status_a, new_status: status_b)["checked"]).to be_present
      expect(checkbox_for(old_status: status_b, new_status: status_a)["checked"]).to be_nil
    end

    it "submits no indeterminate marker" do
      expect(indeterminate_marker_for(old_status: status_a, new_status: status_b)).to be_nil
    end
  end

  describe "with several roles selected" do
    let(:roles) { [role, other_role] }

    context "when only some of them allow a transition" do
      let(:workflows) { [transition(old_status: status_a, new_status: status_b, for_role: role)] }

      it "renders the pair indeterminate and marks it so saving preserves it" do
        checkbox = checkbox_for(old_status: status_a, new_status: status_b)

        expect(checkbox["checked"]).to be_nil
        expect(checkbox["data-indeterminate"]).to eq("true")
        expect(indeterminate_marker_for(old_status: status_a, new_status: status_b)).to be_present
      end
    end

    context "when all of them allow a transition" do
      let(:workflows) do
        [
          transition(old_status: status_a, new_status: status_b, for_role: role),
          transition(old_status: status_a, new_status: status_b, for_role: other_role)
        ]
      end

      it "renders the pair plainly checked" do
        expect(checkbox_for(old_status: status_a, new_status: status_b)["checked"]).to be_present
        expect(indeterminate_marker_for(old_status: status_a, new_status: status_b)).to be_nil
      end
    end

    context "when a status was only just added" do
      let(:workflows) { [transition(old_status: status_a, new_status: status_b, for_role: role)] }
      let(:added_status_ids) { [status_b.id] }

      it "pre-checks its pairs for every role rather than showing them indeterminate" do
        checkbox = checkbox_for(old_status: status_a, new_status: status_b)

        expect(checkbox["checked"]).to be_present
        expect(checkbox["data-indeterminate"]).to be_nil
        expect(indeterminate_marker_for(old_status: status_a, new_status: status_b)).to be_nil
      end
    end
  end

  describe "readonly" do
    let(:readonly) { true }

    it "disables every checkbox and drops the bulk toggles" do
      expect(rendered_component.css("input[type=checkbox]:not([disabled])")).to be_empty
      expect(rendered_component).to have_no_button("Check all")
      expect(rendered_component).to have_no_button("Uncheck all")
    end
  end

  describe "tab headings" do
    context "with the author tab" do
      let(:tab) { "author" }

      it "names the transitions as additional to the default ones" do
        expect(rendered_component).to have_css("h3", text: I18n.t(:label_additional_workflow_transitions_for_author))
      end
    end

    context "with the always tab" do
      it "renders no heading" do
        expect(rendered_component).to have_no_css("h3")
      end
    end
  end
end
