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

RSpec.describe WorkPackages::Moves::FormComponent, type: :component do
  include OpenProject::StaticRouting::UrlHelpers

  subject(:rendered_component) do
    with_controller_class(WorkPackages::MovesController) do
      with_request_url("/work_packages/move/new") do
        render_inline(component)
      end
    end
  end

  let(:component) { build_component }
  let(:type) { create(:type, name: "Bug") }
  let(:project) { create(:project, types: [type]) }
  let(:target_project) { create(:project, types: [type]) }
  let(:work_package) { create(:work_package, project:, type:) }
  let(:status) { create(:status) }
  let!(:priority) { create(:priority, name: "High") }
  let(:version) { create(:version, project: target_project) }

  def build_component(**params)
    described_class.new(
      work_packages: [work_package],
      project:,
      target_project:,
      types: target_project.types,
      target_type: type,
      available_versions: [version],
      available_statuses: [status],
      notes: "Move notes",
      **params
    )
  end

  it "renders the move form" do
    expect(rendered_component).to have_css("form#move_form")
    expect(rendered_component).to have_field(:"ids[]", type: :hidden, with: work_package.id.to_s)
    expect(rendered_component).to have_select(:new_type_id, selected: type.name)
    expect(rendered_component).to have_field(:notes, with: "Move notes")
  end

  it "wires the refresh-on-form-changes controller" do
    expect(rendered_component).to have_css(
      "form[data-controller='refresh-on-form-changes']" \
      "[data-refresh-on-form-changes-target='form']"
    )
  end

  context "with a required custom field on the target type" do
    let!(:custom_field) do
      create(:string_wp_custom_field,
             name: "Risk score",
             is_required: true,
             types: [type],
             projects: [project, target_project])
    end

    it "renders the required marker as an HTML element, not escaped text" do
      expect(rendered_component).to have_css("label.form--label span.required", text: "*")
      expect(rendered_component).to have_no_text('<span class="required">')
    end
  end
end
