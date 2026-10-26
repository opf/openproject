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

RSpec.describe ITSM::Mailboxes::FetchContract, :check_errors_i18n, with_flag: { helpdesk: true } do
  include_context "ModelContract shared context"

  subject(:contract) { described_class.new(mailbox, current_user) }

  let(:mailbox) { create(:itsm_mailbox, project:, active:) }
  let(:project) { create(:project) }
  let(:active) { true }
  let(:current_user) { User.system }

  it_behaves_like "contract is valid"

  context "when the mailbox is paused" do
    let(:active) { false }

    it_behaves_like "contract is invalid", base: :inactive
  end

  context "when the helpdesk is disabled in the project" do
    let(:project) { create(:project, disable_modules: :helpdesk) }

    it_behaves_like "contract user is unauthorized"
  end

  context "when the project is archived" do
    let(:project) { create(:project, active: false) }

    it_behaves_like "contract user is unauthorized"
  end

  context "with the feature flag off", with_flag: { helpdesk: false } do
    it_behaves_like "contract user is unauthorized"
  end

  context "with a project member without the permission" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it_behaves_like "contract user is unauthorized"
  end
end
