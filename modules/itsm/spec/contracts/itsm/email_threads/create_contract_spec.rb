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
require "contracts/shared/model_contract_shared_context"
require_module_spec_helper

RSpec.describe ITSM::EmailThreads::CreateContract, :check_errors_i18n do
  include_context "ModelContract shared context"

  let(:contract) { described_class.new(thread, current_user) }
  let(:current_user) { build_stubbed(:user) }
  let(:work_package) { build_stubbed(:work_package) }
  let(:thread) { ITSM::EmailThread.new(work_package:, requester_email: "jane@customer.example") }
  let(:permissions) { %i[add_work_package_comments] }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_work_package(*permissions, work_package:)
    end
  end

  it_behaves_like "contract is valid"

  context "when the user may not comment on the work package" do
    let(:permissions) { [] }

    it_behaves_like "contract user is unauthorized"
  end

  context "without a requester" do
    let(:thread) { ITSM::EmailThread.new(work_package:) }

    it_behaves_like "contract is invalid", requester_email: :blank
  end
end
