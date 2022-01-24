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

describe Queries::Scopes::Visible, type: :model do
  describe '.visible' do
    subject(:scope) { ::Query.visible(user) }

    let(:user) do
      create(:user,
                        member_in_project: project,
                        member_with_permissions: permissions)
    end
    let(:permissions) { %i[view_work_packages] }
    let!(:private_user_query) do
      create(:query,
                        project: project,
                        user: user)
    end
    let!(:private_other_user_query) do
      create(:query,
                        project: project)
    end
    let!(:private_user_query_lacking_permissions) do
      create(:query,
                        project: create(:project,
                                                   members: { user => create(:role, permissions: []) }),
                        user: user)
    end
    let!(:public_query) do
      create(:query,
                        project: project,
                        public: true)
    end
    let!(:public_query_lacking_permissions) do
      create(:query,
                        project: create(:project,
                                                   members: { user => create(:role, permissions: []) }),
                        public: true)
    end
    let!(:global_user_query) do
      create(:query,
                        project: nil,
                        user: user)
    end
    let!(:global_other_user_query) do
      create(:query,
                        project: nil)
    end
    let(:project) { create(:project) }
    let(:public_project) { create(:public_project) }

    context 'with the user having the :view_work_packages permission' do
      it 'returns the queries that are public or that are the user`s' do
        expect(scope)
          .to match_array([private_user_query, public_query, global_user_query, global_other_user_query])
      end
    end

    context 'without the user having the :view_work_packages permission' do
      let(:permissions) { [] }

      it 'is empty' do
        expect(scope)
          .to be_empty
      end
    end
  end
end
