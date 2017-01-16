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
require_relative '../support/shared/become_member'

describe Group, type: :model do
  include BecomeMember

  let(:group) { FactoryGirl.build(:group) }
  let(:user) { FactoryGirl.build(:user) }
  let(:status) { FactoryGirl.create(:status) }
  let(:role) { FactoryGirl.create :role, permissions: [:view_work_packages] }

  let(:projects) do
    projects = FactoryGirl.create_list :project_with_types, 20

    projects.each do |project|
      add_user_to_project! user: group, project: project, role: role
    end

    projects
  end

  let!(:work_packages) do
    projects.flat_map do |project|
      work_packages = FactoryGirl.create_list(
        :work_package,
        1,
        type: project.types.first,
        author: user,
        project: project,
        status: status)

      work_packages.first.tap do |wp|
        wp.assigned_to = group
        wp.save!
      end
    end
  end

  let(:users) { FactoryGirl.create_list :user, 100 }

  before do
    users.each do |user|
      group.add_member! user
    end
  end

  describe '#destroy' do
    describe 'work packages assigned to the group' do
      let(:deleted_user) { DeletedUser.first }

      before do
        expect(::OpenProject::Notifications)
          .to receive(:send).with(:member_removed, any_args)
          .exactly(projects.size).times

        puts "Destroying group ..."
        start = Time.now.to_i
        group.destroy
        @seconds = Time.now.to_i - start

        puts "Destroyed group in #{@seconds} seconds"

        expect(@seconds < 10).to eq true
      end

      it 'should reassign the work package to nobody and clean up the journals' do
        work_packages.each do |wp|
          wp.reload

          expect(wp.assigned_to).to eq(deleted_user)

          wp.journals.each do |journal|
            journal.data.assigned_to_id == deleted_user.id
          end
        end
      end
    end
  end
end
