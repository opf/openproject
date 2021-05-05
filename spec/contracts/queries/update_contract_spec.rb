#-- encoding: UTF-8

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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'contracts/shared/model_contract_shared_context'

describe Queries::UpdateContract do
  include_context 'ModelContract shared context'

  let(:project) { FactoryBot.build_stubbed :project }
  let(:query) do
    FactoryBot.build_stubbed(:query, project: project, is_public: public, user: user)
  end

  let(:current_user) do
    FactoryBot.build_stubbed(:user) do |user|
      allow(user)
        .to receive(:allowed_to?) do |permission, permission_project|
        permissions.include?(permission) && project == permission_project
      end
    end
  end
  let(:contract) { described_class.new(query, current_user) }

  before do
    # Assume project is always visible
    allow(contract).to receive(:project_visible?).and_return true
  end

  describe 'private query' do
    let(:public) { false }

    context 'when user is author' do
      let(:user) { current_user }

      context 'user has no permission to save' do
        let(:permissions) { %i(edit_work_packages) }

        it_behaves_like 'contract user is unauthorized'
      end

      context 'user has permission to save' do
        let(:permissions) { %i(save_queries) }

        it_behaves_like 'contract is valid'
      end
    end

    context 'when user is someone else' do
      let(:user) { FactoryBot.build_stubbed :user }
      let(:permissions) { %i(save_queries) }

      it_behaves_like 'contract user is unauthorized'
    end
  end

  describe 'public query' do
    let(:public) { true }
    let(:user) { nil }

    context 'user has no permission to save' do
      let(:permissions) { %i(invalid_permission) }

      it_behaves_like 'contract user is unauthorized'
    end

    context 'user has no permission to manage public' do
      let(:permissions) { %i(manage_public_queries) }

      it_behaves_like 'contract is valid'
    end

    context 'user has permission to save only own' do
      let(:permissions) { %i(save_queries) }

      it_behaves_like 'contract user is unauthorized'
    end
  end
end
