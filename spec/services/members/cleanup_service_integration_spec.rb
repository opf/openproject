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

describe Members::CleanupService, 'integration', type: :model do
  subject(:service_call) { instance.call }

  let(:user) { FactoryBot.create(:user) }
  let(:users) { [user] }
  let(:project) { FactoryBot.create(:project) }
  let(:projects) { [project]}
  let(:instance) do
    described_class.new(users, projects)
  end

  describe 'category unassignment' do
    let!(:category) do
      FactoryBot.build(:category, project: project, assigned_to: user).tap do |c|
        c.save(validate: false)
      end
    end

    it 'sets assigned_to to nil' do
      service_call

      expect(category.reload.assigned_to)
        .to be_nil
    end

    context 'with the user having a membership with an assignable role' do
      before do
        FactoryBot.create(:member,
                          principal: user,
                          project: project,
                          roles: [FactoryBot.create(:role, assignable: true)])
      end

      it 'keeps assigned_to to the user' do
        service_call

        expect(category.reload.assigned_to)
          .to eql user
      end
    end

    context 'with the user having a membership with an unassignable role' do
      before do
        FactoryBot.create(:member,
                          principal: user,
                          project: project,
                          roles: [FactoryBot.create(:role, assignable: false)])
      end

      it 'sets assigned_to to nil' do
        service_call

        expect(category.reload.assigned_to)
          .to be_nil
      end
    end
  end

  describe 'watcher pruning' do
    let(:work_package) do
      FactoryBot.create :work_package,
                        project: project
    end
    let!(:watcher) do
      FactoryBot.build(:watcher,
                       watchable: work_package,
                       user: user) do |w|
        w.save(validate: false)
      end
    end

    it 'removes the watcher' do
      service_call

      expect { watcher.reload }
        .to raise_error ActiveRecord::RecordNotFound
    end

    context 'with the user having a membership granting the right to view the watchable' do
      before do
        FactoryBot.create(:member,
                          principal: user,
                          project: project,
                          roles: [FactoryBot.create(:role, permissions: [:view_work_packages])])
      end

      it 'keeps the watcher' do
        service_call

        expect { watcher.reload }
          .not_to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'with the user having a membership not granting the right to view the watchable' do
      before do
        FactoryBot.create(:member,
                          principal: user,
                          project: project,
                          roles: [FactoryBot.create(:role, permissions: [])])
      end

      it 'keeps the watcher' do
        service_call

        expect { watcher.reload }
          .to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
