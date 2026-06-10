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

RSpec.describe Backlogs::Projects::BacklogsTypesAndStatusesContract, type: :model do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:user) }

  let(:allowed_type) { create(:type_feature) }
  let(:other_type) { create(:type_task) }

  let(:project) { create(:project, types: [allowed_type]) }
  let(:permissions) { %i[select_backlog_types_and_statuses] }

  subject(:contract) { described_class.new(project, current_user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project(*permissions, project:)
    end
  end

  describe "validations" do
    context "with valid done statuses and excluded types" do
      let!(:open_status) { create(:status, is_closed: false) }

      before do
        project.done_status_ids = [open_status.id]
        project.backlog_excluded_type_ids = [allowed_type.id]
      end

      it_behaves_like "contract is valid"
    end

    context "with empty done_status_ids" do
      before { project.done_status_ids = [] }

      it_behaves_like "contract is valid"
    end

    context "when user cannot update backlogs type and status settings" do
      let(:permissions) { [] }

      it_behaves_like "contract user is unauthorized"
    end

    context "when done_status_ids contains a non-existing status id" do
      before do
        allow(project).to receive(:done_status_ids).and_return([Status.maximum(:id).to_i + 1000])
      end

      it_behaves_like "contract is invalid", done_status_ids: :invalid
    end

    context "when backlog_excluded_type_ids contains a type that is not enabled in the project" do
      before do
        project.backlog_excluded_type_ids = [other_type.id]
      end

      it_behaves_like "contract is invalid", backlog_excluded_type_ids: :invalid
    end
  end

  describe "#validate_model?" do
    it "does not run full model validations" do
      expect(contract.validate_model?).to be(false)
    end
  end
end
