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

RSpec.describe Workflows::StatusRemovalDangerDialogComponent, type: :component do
  let(:role) { build_stubbed(:project_role) }
  let(:wizard) { false }

  # The dialog submits with GET, which drops the query string of its action, so the matrix
  # it reloads only sees what is submitted as a field.
  let(:context) do
    instance_double(Workflows::MatrixContext,
                    tab: "author",
                    roles: [role],
                    requested_status_ids: [1],
                    removed_displayed_status_ids: [2],
                    wizard?: wizard,
                    matrix_path: "/types/1/workflow/matrix")
  end

  subject(:rendered_component) { render_inline(described_class.new(context:)) }

  it "submits the tab, roles and statuses the matrix was showing" do
    expect(rendered_component).to have_field("tab", type: :hidden, with: "author")
    expect(rendered_component).to have_field("role_ids[]", type: :hidden, with: role.id.to_s)
    expect(rendered_component).to have_field("status_ids[]", type: :hidden, with: "1")
  end

  it "does not claim to be the wizard outside of it" do
    expect(rendered_component).to have_no_field("wizard", type: :hidden)
  end

  context "within the type creation wizard" do
    let(:wizard) { true }

    it "keeps the matrix in wizard mode" do
      expect(rendered_component).to have_field("wizard", type: :hidden, with: "true")
    end
  end
end
