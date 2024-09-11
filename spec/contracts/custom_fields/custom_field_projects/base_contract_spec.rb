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

RSpec.describe CustomFields::CustomFieldProjects::BaseContract do
  include_context "ModelContract shared context"

  let(:contract) { described_class.new(custom_field_project, user) }
  let(:user) { build_stubbed(:admin) }
  let(:custom_field_project) { build_stubbed(:custom_fields_project) }

  context "when the custom field is for all" do
    let(:custom_field) { build_stubbed(:custom_field, is_for_all: true) }
    let(:custom_field_project) { build_stubbed(:custom_fields_project, custom_field:) }

    it_behaves_like "contract is invalid", custom_field_id: :is_for_all_cannot_modify
  end

  context "with authorised user" do
    let(:user) { build_stubbed(:user) }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:select_custom_fields, project: custom_field_project.project)
      end
    end

    it_behaves_like "contract is valid"
  end

  context "with unauthorised user" do
    let(:user) { build_stubbed(:user) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  include_examples "contract reuses the model errors"
end
