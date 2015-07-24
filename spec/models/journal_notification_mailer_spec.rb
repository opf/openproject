#-- encoding: UTF-8
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

describe JournalNotificationMailer do
  let(:project) { FactoryGirl.create(:project_with_types) }
  let(:user) do
    FactoryGirl.build(:user,
                      mail_notification: 'all',
                      member_in_project: project)
  end
  let(:work_package) do
    FactoryGirl.create(:work_package,
                       project: project,
                       author: user,
                       type: project.types.first)
  end
  let(:notifications) { [] }

  before do
    allow(User).to receive(:current).and_return(user)
    allow(Setting).to receive(:notified_events).and_return(notifications)

    ActionMailer::Base.deliveries.clear
  end

  shared_examples_for 'handles deliveries' do |notification_setting|
    context 'sends a notification' do
      let(:notifications) { [notification_setting] }

      it do
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end
    end

    it 'sends no notification' do
      expect(ActionMailer::Base.deliveries.size).to eq(0)
    end
  end

  describe 'journal creation' do
    context 'work_package_created' do
      before do
        FactoryGirl.create(:work_package, project: project)
      end

      context 'sends a notification' do
        let(:notifications) { ['work_package_added'] }

        it do
          expect(ActionMailer::Base.deliveries.size).to eq(1)
        end
      end

      it 'sends no notification' do
        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end
    end

    context 'work_package_updated' do
      before do
        work_package.add_journal(user)
        work_package.subject = 'A change to the issue'
        expect(work_package.save(validate: false)).to be_truthy
      end

      it_behaves_like 'handles deliveries', 'work_package_updated'
    end

    context 'work_package_note_added' do
      before do
        work_package.add_journal(user, 'This update has a note')
        expect(work_package.save(validate: false)).to be_truthy
        work_package.recreate_initial_journal!
      end

      it_behaves_like 'handles deliveries', 'work_package_note_added'
    end

    context 'status_updated' do
      before do
        work_package.add_journal(user)
        work_package.status = FactoryGirl.build(:status)
        expect(work_package.save(validate: false)).to be_truthy
      end

      it_behaves_like 'handles deliveries', 'status_updated'
    end

    context 'work_package_priority_updated' do
      before do
        work_package.add_journal(user)
        work_package.priority = IssuePriority.generate!
        expect(work_package.save(validate: false)).to be_truthy
      end

      it_behaves_like 'handles deliveries', 'work_package_priority_updated'
    end

    context 'send_notification disabled' do
      before do
        allow(JournalManager).to receive(:send_notification).and_return(false)
        FactoryGirl.create(:work_package, project: project) # Provoke notification
      end

      it 'sends no notification' do
        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end
    end
  end
end
