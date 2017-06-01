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

describe Api::V2::TimelinesController, type: :controller do
  # ===========================================================
  # Helpers
  def self.become_admin
    let(:current_user) { FactoryGirl.create(:admin) }
  end

  def self.become_non_member
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      current_user.memberships.select { |m| m.project_id == project.id }.each(&:destroy)
    end
  end

  def self.become_member_with_all_permissions
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, permissions: [:view_timelines, :edit_timelines, :delete_timelines])
      member = FactoryGirl.build(:member, user: current_user, project: project)
      member.roles = [role]
      member.save!
    end
  end

  def self.become_member_with_view_permissions
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, permissions: [:view_timelines])
      member = FactoryGirl.build(:member, user: current_user, project: project)
      member.roles = [role]
      member.save!
    end
  end

  def self.become_member_with_edit_permissions
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, permissions: [:edit_timelines])
      member = FactoryGirl.build(:member, user: current_user, project: project)
      member.roles = [role]
      member.save!
    end
  end

  def self.become_member_with_delete_permissions
    let(:current_user) { FactoryGirl.create(:user) }

    before do
      role   = FactoryGirl.create(:role, permissions: [:delete_timelines])
      member = FactoryGirl.build(:member, user: current_user, project: project)
      member.roles = [role]
      member.save!
    end
  end

  before do
    allow(User).to receive(:current).and_return current_user
  end

  shared_examples_for 'all actions related to all timelines within a project' do
    describe 'w/o a given project' do
      become_admin

      it 'renders a 404 Not Found page' do
        fetch

        expect(response.response_code).to eq(404)
      end
    end

    describe 'w/ an unknown project' do
      become_admin

      it 'renders a 404 Not Found page' do
        fetch project_id: '4711'

        expect(response.response_code).to eq(404)
      end
    end

    describe 'w/ a known project' do
      let(:project) { FactoryGirl.create(:project, identifier: 'test_project') }

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 403 Forbidden page' do
          fetch project_id: project.identifier

          expect(response.response_code).to eq(403)
        end
      end
    end
  end

  shared_examples_for 'all actions related to an existing timeline' do
    become_admin

    describe 'w/o a valid timelines id' do
      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          fetch id: '4711'

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          fetch project_id: '4711', id: '1337'

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, identifier: 'test_project') }

        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            fetch project_id: project.id, id: '1337'

            expect(response.response_code).to be === 403
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_all_permissions

          it 'raises ActiveRecord::RecordNotFound errors' do
            expect {
              fetch project_id: project.id, id: '1337'
            }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe 'w/ a valid timelines id' do
      let(:project)  { FactoryGirl.create(:project, identifier: 'test_project') }
      let(:timeline) { FactoryGirl.create(:timelines, project_id: project.id, name: 'b') }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          fetch id: timeline.id

          expect(response.response_code).to eq(404)
        end
      end

      describe 'w/ a different project' do
        let(:other_project)  { FactoryGirl.create(:project, identifier: 'other') }

        it 'raises ActiveRecord::RecordNotFound errors' do
          expect {
            fetch project_id: other_project.identifier, id: timeline.id
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'w/ a proper project' do
        describe 'w/o being a member or administrator' do
          become_non_member

          it 'renders a 403 Forbidden page' do
            fetch project_id: project.id, id: timeline.id

            expect(response.response_code).to eq(403)
          end
        end

        describe 'w/ the current user being a member' do
          become_member_with_all_permissions

          it 'assigns the timeline' do
            fetch project_id: project.id, id: timeline.id
            expect(assigns(:timeline)).to eq(timeline)
          end
        end
      end
    end
  end
end
