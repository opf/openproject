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

RSpec.describe Import::JiraTypeVariants::FindOrCreateService do
  shared_let(:user) { build_stubbed(:admin) }
  shared_let(:jira_import) { create(:jira_import, author: user) }
  shared_let(:type) { create(:type, name: "Task") }
  shared_let(:project) { create(:project) }

  let(:created_variant) { build_stubbed(:type_variant) }
  let(:create_result) { ServiceResult.success(result: created_variant) }
  let(:create_service) { instance_double(Import::JiraTypeVariants::CreateService, call: create_result) }

  let(:service) { described_class.new(user:, jira_import:) }

  subject(:call) { service.call(type:, project:) }

  before do
    allow(Import::JiraTypeVariants::CreateService).to receive(:new).with(user:, jira_import:).and_return(create_service)
  end

  context "when the project has no variant of the type yet" do
    it "creates a new variant and returns it" do
      expect(call).to be_success
      expect(call.result).to eq(created_variant)
      expect(create_service).to have_received(:call).with(type:, project:)
    end
  end

  context "with existing global variants and project-specific variants for other types" do
    let(:other_type) { create(:type, name: "Bug") }

    before do
      create(:project_owned_type_variant, type: other_type, project:)
      create(:type_variant, type:)
    end

    it "still creates a new variant and returns it" do
      expect(call).to be_success
      expect(call.result).to eq(created_variant)
      expect(create_service).to have_received(:call).with(type:, project:)
    end

    context "when the project already owns a project-specific variant" do
      let!(:existing_variant) { create(:project_owned_type_variant, type:, project:) }

      it "returns it without creating another" do
        expect(call).to be_success
        expect(call.result).to eq(existing_variant)
        expect(create_service).not_to have_received(:call)
      end
    end
  end
end
