#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe API::V3::Projects::ProjectsAPI, type: :request do
  include API::V3::Utilities::PathHelper

  let(:admin) { FactoryGirl.create(:admin) }

  describe 'available assignees' do
    let(:project) { FactoryGirl.build_stubbed(:project) }

    before { allow(Project).to receive(:find).and_return(project) }

    shared_context 'request available assignees' do
      before { get api_v3_paths.available_assignees project.id }
    end

    it_behaves_like 'safeguarded API' do
      include_context 'request available assignees'
    end

    describe 'response' do
      before { allow(User).to receive(:current).and_return(admin) }

      shared_examples_for 'returns available assignees' do |total, count|
        include_context 'request available assignees'

        it_behaves_like 'API V3 collection response', total, count, 'User'
      end

      describe 'users' do
        let(:user) { FactoryGirl.build_stubbed(:user) }
        let(:user2) { FactoryGirl.build_stubbed(:user) }

        context 'single user' do
          before do
            allow(project).to receive(:possible_assignees).and_return([user])

            allow(user).to receive(:created_on).and_return(user.created_at)
            allow(user).to receive(:updated_on).and_return(user.created_at)
          end

          it_behaves_like 'returns available assignees', 1, 1
        end

        context 'multiple users' do
          before do
            allow(project).to receive(:possible_assignees).and_return([user, user2])

            allow(user).to receive(:created_on).and_return(user.created_at)
            allow(user).to receive(:updated_on).and_return(user.created_at)

            allow(user2).to receive(:created_on).and_return(user.created_at)
            allow(user2).to receive(:updated_on).and_return(user.created_at)
          end

          it_behaves_like 'returns available assignees', 2, 2
        end
      end

      describe 'groups' do
        let(:group) { FactoryGirl.create(:group) }
        let(:project) { FactoryGirl.create(:project) }

        before { allow(Project).to receive(:find).and_return(project) }

        context 'with work_package_group_assignment' do
          before do
            allow(Setting).to receive(:work_package_group_assignment?).and_return(true)
            project.add_member! group, FactoryGirl.create(:role)
          end

          it_behaves_like 'returns available assignees', 1, 1
        end

        context 'without work_package_group_assignment' do
          before do
            allow(Setting).to receive(:work_package_group_assignment?).and_return(false)
            project.add_member! group, FactoryGirl.create(:role)
          end

          it_behaves_like 'returns available assignees', 0, 0
        end
      end
    end
  end
end
