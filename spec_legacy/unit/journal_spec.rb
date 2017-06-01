#-- encoding: UTF-8
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
require 'legacy_spec_helper'

describe Journal,
         type: :model,
         with_settings: { notified_events: %w(work_package_updated) } do
  fixtures :all

  it 'create should send email notification' do
    issue = WorkPackage.first
    if issue.journals.empty?
      issue.add_journal(User.current, 'This journal represents the creationa of journal version 1')
      issue.save
    end

    issue.reload
    issue.update_attribute(:subject, 'New subject to trigger automatic journal entry')
    assert_equal 2, ActionMailer::Base.deliveries.size
  end

  it 'create should not send email notification if told not to' do
    issue = WorkPackage.first
    user = User.first
    journal = issue.add_journal(user, 'A note')
    JournalManager.send_notification = false

    assert_difference('Journal.count') do
      assert issue.save
    end
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  specify 'creating the initial journal should track the changes from creation' do
    Journal.delete_all
    @project = FactoryGirl.create(:project)
    issue = WorkPackage.new do |i|
      i.project = @project
      i.subject = 'Test initial journal'
      i.type = @project.types.first
      i.author = FactoryGirl.create(:user)
      i.description = 'Some content'
    end

    assert_difference('Journal.count') do
      assert issue.save
    end

    journal = issue.reload.journals.first
    assert_equal [nil, 'Test initial journal'], journal.details[:subject]
    assert_equal [nil, @project.id], journal.details[:project_id]
    assert_equal [nil, 'Some content'], journal.details[:description]
  end

  specify 'creating a journal should update the updated_on value of the parent record (touch)' do
    @user = FactoryGirl.create(:user)
    @project = FactoryGirl.create(:project)
    @issue = FactoryGirl.create(:work_package, project: @project)
    start = @issue.updated_at
    sleep(1) # TODO: massive hack to make sure the timestamps are different. switch to timecop later

    assert_difference('Journal.count') do
      @issue.add_journal(@user, 'A note')
      @issue.save
    end

    refute_equal start, @issue.reload.updated_at
  end

  specify 'accessing #journaled on a Journal should not error (parent class)' do
    journal = Journal.new
    expect {
      assert_equal nil, journal.journable
    }.not_to raise_error
  end

  specify 'setting journal fields through the journaled object for creation' do
    @issue = FactoryGirl.create(:work_package)

    @issue.add_journal @issue.author, 'Test setting fields on Journal from Issue'
    assert_difference('Journal.count') do
      assert @issue.save
    end

    assert_equal 'Test setting fields on Journal from Issue', @issue.last_journal.notes
    assert_equal @issue.author, @issue.last_journal.user
  end
end
