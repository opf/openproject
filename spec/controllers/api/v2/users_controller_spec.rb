#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Api::V2::UsersController, type: :controller do
  shared_context 'As an admin' do
    let(:current_user) { FactoryGirl.create(:admin) }

    before { allow(User).to receive(:current).and_return current_user }
  end

  shared_context 'As a normal user' do
    let(:current_user) { FactoryGirl.create(:user) }

    before { allow(User).to receive(:current).and_return current_user }
  end

  shared_examples_for 'valid user API call' do
    it { expect(assigns(:users).size).to eq(user_count) }

    it { expect(response).to render_template('api/v2/users/index') }
  end

  describe 'index.json' do
    describe 'scopes' do
      shared_examples_for 'no scope provided' do
        it { expect(response.status).to eq(400) }
      end

      context 'no scope' do
        before do
          get 'index', format: :json
        end

        it_behaves_like 'no scope provided'
      end

      context 'empty scope' do
        before do
          get 'index', params: { ids: '' }, format: :json
        end

        it_behaves_like 'no scope provided'
      end

      context 'filled scope' do
        before do
          get 'index', params: { ids: '1' }, format: :json
        end

        it_behaves_like 'valid user API call' do
          let(:user_count) { 0 }
        end
      end
    end

    describe 'with a group' do
      let(:ids) { Group.all.map(&:id).join(',') }
      let!(:group) { FactoryGirl.create(:group) }

      context 'as an admin' do
        include_context 'As an admin'

        before do
          get 'index', params: { ids: ids }, format: :json
        end

        it_behaves_like 'valid user API call' do
          let(:user_count) { 1 }
        end
      end
    end

    describe 'with 3 users' do
      let(:ids) { User.all.map(&:id).join(',') }

      before do 3.times { FactoryGirl.create(:user) } end

      context 'as an admin' do
        include_context 'As an admin'

        before do
          get 'index', params: { ids: ids }, format: :json
        end

        it_behaves_like 'valid user API call' do
          let(:user_count) { 4 }
        end
      end

      context 'as a normal user' do
        include_context 'As a normal user'

        before do
          get 'index', params: { ids: ids }, format: 'json'
        end

        it_behaves_like 'valid user API call' do
          let(:user_count) { 4 }
        end
      end
    end

    describe 'within a project' do
      include_context 'As a normal user'

      let(:project) { FactoryGirl.create :project }
      let!(:member)  { FactoryGirl.create :user, member_in_project: project }

      let!(:non_member) { FactoryGirl.create :user }

      before do
        get 'index', params: { project_id: project.to_param }, format: :json
      end

      it_behaves_like 'valid user API call' do
        let(:user_count) { 1 }
      end
    end

    describe 'search for ids' do
      include_context 'As an admin'

      let (:user_1) { FactoryGirl.create(:user) }
      let (:user_2) { FactoryGirl.create(:user) }

      before do
        get 'index', params: { ids: "#{user_1.id},#{user_2.id}" }, format: 'json'
      end

      subject { assigns(:users) }

      it { expect(subject.size).to eq(2) }

      it { expect(subject).to include(user_1, user_2) }
    end
  end
end
