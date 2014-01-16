#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
require File.expand_path('../../test_helper', __FILE__)

class JournalObserverTest < ActiveSupport::TestCase
  def setup
    super
    @type = FactoryGirl.create :type_with_workflow
    @project = FactoryGirl.create :project,
                                  :types => [@type]
    @workflow = @type.workflows.first
    @user = FactoryGirl.create :user,
                               :mail_notification => 'all',
                               :member_in_project => @project
    @issue = FactoryGirl.create :work_package,
                                :project => @project,
                                :author => @user,
                                :type => @type,
                                :status => @workflow.old_status

    @user.members.first.roles << @workflow.role

    User.stubs(:current).returns(@user)

    ActionMailer::Base.deliveries.clear
  end

  context "#after_create for 'issue_updated'" do
    should "should send a notification when configured as a notification" do
      Setting.notified_events = ['issue_updated']
      assert_difference('ActionMailer::Base.deliveries.size', +1) do
        @issue.add_journal(@user)
        @issue.subject = "A change to the issue"
        assert @issue.save(validate: false)
      end
    end

    should "not send a notification with not configured" do
      Setting.notified_events = []
      assert_no_difference('ActionMailer::Base.deliveries.size') do
        @issue.add_journal(@user)
        @issue.subject = "A change to the issue"
        assert @issue.save(validate: false)
      end
    end
  end

  context "#after_create for 'issue_note_added'" do
    should "should send a notification when configured as a notification" do
      @issue.recreate_initial_journal!

      Setting.notified_events = ['issue_note_added']
      assert_difference('ActionMailer::Base.deliveries.size', +1) do
        @issue.add_journal(@user, 'This update has a note')
        assert @issue.save(validate: false)
      end
    end

    should "not send a notification with not configured" do
      Setting.notified_events = []
      assert_no_difference('ActionMailer::Base.deliveries.size') do
        @issue.add_journal(@user, 'This update has a note')
        assert @issue.save(validate: false)
      end
    end
  end

  context "#after_create for 'status_updated'" do
    should "should send a notification when configured as a notification" do
      Setting.notified_events = ['status_updated']
      assert_difference('ActionMailer::Base.deliveries.size', +1) do
        @issue.add_journal(@user)
        @issue.status = @workflow.new_status
        assert @issue.save(validate: false)
      end
    end

    should "not send a notification with not configured" do
      Setting.notified_events = []
      assert_no_difference('ActionMailer::Base.deliveries.size') do
        @issue.add_journal(@user)
        @issue.status = @workflow.new_status
        assert @issue.save(validate: false)
      end
    end
  end

  context "#after_create for 'issue_priority_updated'" do
    should "should send a notification when configured as a notification" do
      Setting.notified_events = ['issue_priority_updated']
      assert_difference('ActionMailer::Base.deliveries.size', +1) do
        @issue.add_journal(@user)
        @issue.priority = IssuePriority.generate!
        assert @issue.save(validate: false)
      end
    end

    should "not send a notification with not configured" do
      Setting.notified_events = []
      assert_no_difference('ActionMailer::Base.deliveries.size') do
        @issue.add_journal(@user)
        @issue.priority = IssuePriority.generate!
        assert @issue.save(validate: false)
      end
    end
  end
end
