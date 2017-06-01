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

require 'rack/test'

shared_examples_for 'available principals' do |principals|
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    FactoryGirl.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:other_user) do
    FactoryGirl.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:project) { FactoryGirl.create(:project) }
  let(:group) do
    group = FactoryGirl.create(:group)
    project.add_member! group, FactoryGirl.create(:role)
    group
  end
  let(:permissions) { [:view_work_packages] }

  shared_context "request available #{principals}" do
    before { get href }
  end

  before do
    allow(User).to receive(:current).and_return(current_user)
  end

  describe 'response' do
    shared_examples_for "returns available #{principals}" do |total, count|
      include_context "request available #{principals}"

      it_behaves_like 'API V3 collection response', total, count, 'User'
    end

    describe 'users' do
      context 'single user' do
        # The current user

        it_behaves_like "returns available #{principals}", 1, 1
      end

      context 'multiple users' do
        before do
          other_user
          # and the current user
        end

        it_behaves_like "returns available #{principals}", 2, 2
      end
    end

    describe 'groups' do
      let!(:users) { [group] }

      context 'with work_package_group_assignment' do
        before do
          allow(Setting).to receive(:work_package_group_assignment?).and_return(true)
        end

        # current user and group
        it_behaves_like "returns available #{principals}", 2, 2
      end

      context 'without work_package_group_assignment' do
        before do
          allow(Setting).to receive(:work_package_group_assignment?).and_return(false)
        end

        # Only the current user
        it_behaves_like "returns available #{principals}", 1, 1
      end
    end
  end

  describe 'if not allowed' do
    include Rack::Test::Methods
    let(:permissions) { [] }
    before { get href }

    it_behaves_like 'unauthorized access'
  end
end
