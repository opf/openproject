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

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe ProjectCustomFieldProjectMappings::BaseContract do
  include_context "ModelContract shared context"

  let(:contract) { described_class.new(project_custom_field_mapping, user) }
  let(:user) { build_stubbed(:admin) }
  let(:project) { build_stubbed(:project) }
  let(:project_custom_field) { build_stubbed(:project_custom_field) }
  let(:project_custom_field_mapping) { build_stubbed(:project_custom_field_project_mapping, project:, project_custom_field:) }

  before { User.current = user }

  context "when the custom field is required" do
    let(:project_custom_field) { build_stubbed(:project_custom_field, is_required: true) }

    it_behaves_like "contract is invalid"
  end

  context "with non-visible custom field and admin user" do
    let(:project_custom_field) { build_stubbed(:project_custom_field, admin_only: true) }

    before do
      allow(ProjectCustomField).to receive(:all).and_return([project_custom_field])
    end

    it_behaves_like "contract is valid"
  end

  context "with non-visible custom field and non-admin user" do
    let(:user) { build_stubbed(:user) }
    let(:project_custom_field) { build_stubbed(:project_custom_field, admin_only: true) }

    before do
      allow(ProjectCustomField).to receive(:visible).and_return([project_custom_field])
    end

    it_behaves_like "contract is invalid"
  end

  include_examples "contract reuses the model errors"
end
