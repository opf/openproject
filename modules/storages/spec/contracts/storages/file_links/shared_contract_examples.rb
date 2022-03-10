#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
require_relative '../../../support/storage_server_helpers'

shared_examples_for 'file_link contract' do
  let(:current_user) { create(:user) }
  let(:role) { create(:existing_role, permissions: [:manage_file_links]) }
  let(:project) { create(:project, members: { current_user => role }) }
  let(:work_package) { create(:work_package, project: project) }
  let(:storage) { create(:storage) }
  let!(:project_storage) { create(:project_storage, project: project, storage: storage) }
  let(:file_link) { create(:file_link, container: work_package, storage: storage) }

  it_behaves_like 'contract is valid for active admins and invalid for regular users'

  describe 'validations' do
    context 'when all attributes are valid' do
      it_behaves_like 'contract is valid'
    end

    context 'when storage_id is invalid' do
      context 'as it is empty' do
        let(:storage_id) { "" }
        let(:file_link) { create(:file_link, container: work_package, storage_id: storage_id) }

        it_behaves_like 'contract is invalid'
      end
    end
  end
end
