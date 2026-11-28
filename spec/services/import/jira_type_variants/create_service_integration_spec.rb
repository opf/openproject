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

RSpec.describe Import::JiraTypeVariants::CreateService, "integration" do
  shared_let(:user) { create(:admin) }
  shared_let(:jira_import) { create(:jira_import, author: user) }
  shared_let(:type) { create(:type, name: "Task") }
  shared_let(:project) { create(:project, name: "Project XYZ", identifier: "xyz", no_types: true) }

  let(:base_variant) { type.default_variant }
  let(:service) { described_class.new(user:, jira_import:) }

  let(:references) { Import::JiraOpenProjectReference.where(jira_import:) }

  subject(:call) { service.call(type:, project:) }

  it "creates a project-owned type variant with own form and workflow and references for them" do
    expect { call }
      .to change(TypeVariant, :count).by(1)
      .and change(Workflow, :count).by(1)
      .and change(FormConfiguration, :count).by(1)
      .and change(Import::JiraOpenProjectReference, :count).by(3)

    expect(call).to be_success

    variant = call.result
    expect(variant).to be_persisted
    expect(variant).to have_attributes(type:, project:, variant_name: "Task", is_default_variant: false)
    expect(variant.form_configuration).not_to eq(base_variant.form_configuration)
    expect(variant.workflow).not_to eq(base_variant.workflow)
  end

  context "when the project already has a task variant" do
    before { create(:type_variant, type:, project:, variant_name: "Task") }

    it "fails and leaves no trace behind" do
      expect { call }
        .to not_change(TypeVariant, :count)
        .and not_change(Workflow, :count)
        .and not_change(FormConfiguration, :count)
        .and not_change(Import::JiraOpenProjectReference, :count)
      expect(call).to be_failure
    end
  end
end
