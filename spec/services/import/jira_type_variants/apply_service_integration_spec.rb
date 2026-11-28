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

RSpec.describe Import::JiraTypeVariants::ApplyService, "integration" do
  shared_let(:user) { create(:admin) }
  shared_let(:jira_import) { create(:jira_import, author: user) }
  shared_let(:type) { create(:type, name: "Task") }

  let(:project) { create(:project, no_types: true) }
  let(:service) { described_class.new(user:, jira_import:) }

  subject(:call) { service.call(type:, project:) }

  it "creates and applies a project-owned variant of the type" do
    expect { call }.to change(TypeVariant, :count).by(1)
    expect(call).to be_success

    variant = call.result
    expect(variant).to have_attributes(type:, project:, is_default_variant: false)
    expect(project.enabled_variants).to include(variant)
  end

  context "when the project has the type's base variant enabled" do
    before { create(:project_type, type:, project:) }

    it "creates and applies a project-owned variant of the type" do
      expect(project.enabled_variants).to include(type.default_variant)

      expect { call }.to change(TypeVariant, :count).by(1)
      expect(call).to be_success

      variant = call.result
      expect(variant).to have_attributes(type:, project:, is_default_variant: false)
      expect(project.enabled_variants).to include(variant)
      expect(project.enabled_variants).not_to include(type.default_variant)
    end
  end

  context "when the project already uses a project-specific variant" do
    let(:variant) { create(:project_owned_type_variant, type:, project:) }

    before { create(:project_type, type:, project:, variant:) }

    it "keeps the variant" do
      expect { call }.not_to change(TypeVariant, :count)
      expect(call).to be_success
      expect(call.result).to eq(variant)
    end
  end
end
