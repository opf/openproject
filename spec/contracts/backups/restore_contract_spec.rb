#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'
require 'contracts/shared/model_contract_shared_context'

RSpec.describe Backups::RestoreContract do
  let(:backup) { create(:backup) }
  let(:contract) { described_class.new nil, current_user, options: { backup_token: }, params: }
  let(:backup_token) { create(:backup_token, user: current_user).plain_value }
  let(:params) { { backup_id: backup.id } }

  include_context 'ModelContract shared context'

  context 'with a regular user who has the :restore_backup permission' do
    let(:current_user) { create(:user, global_permissions: [:restore_backup]) }

    it_behaves_like 'contract is valid'

    context 'with a missing backup' do
      let(:params) { { backup_id: 0 } }

      it_behaves_like 'contract is invalid'
    end

    context 'with an invalid backup token' do
      let(:backup_token) { "42" }

      it_behaves_like 'contract is invalid'
    end
  end

  context 'with a user missing the required permission' do
    let(:current_user) { create(:user) }

    it_behaves_like 'contract is invalid'
  end
end
