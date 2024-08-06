#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

def relative_days(nb_days)
  case nb_days
  when 1 then "tomorrow"
  when 0 then "today"
  when -1 then "yesterday"
  else nb_days > 0 ? "in #{nb_days} days" : "#{-nb_days} days ago"
  end
end

RSpec.describe Notifications::CreateDateAlertsNotificationsJob::AlertableWorkPackages do
  subject { described_class.new(user) }

  shared_let(:today) { Date.current }
  shared_let(:yesterday) { today - 1.day }
  shared_let(:in_1_day) { today + 1.day }

  shared_let(:role) { create(:existing_project_role, permissions: [:view_work_packages]) }
  shared_let(:user) { create(:user, firstname: "main") }
  shared_let(:other_user) { create(:user, firstname: "other") }
  shared_let(:project) { create(:project, name: "main", members: { user => role }) }
  shared_let(:other_project) { create(:project, name: "other", members: { user => role }) }

  shared_let(:status_open) { create(:status, name: "open", is_closed: false) }
  shared_let(:status_closed) { create(:status, name: "closed", is_closed: true) }

  shared_let(:alertable_work_packages) do
    create_list(:work_package, 3, project:, author: user)
  end

  let(:global_notification_settings) { user.notification_settings.first }

  def make_alertable_work_package(attributes = {})
    assignee = attributes.slice(:responsible, :responsible_id).any? ? nil : user
    attributes = attributes.reverse_merge(
      start_date: in_1_day,
      assigned_to: assignee
    )
    wp = alertable_work_packages.shift
    wp.update!(attributes)
    wp
  end

  ### open / closed work package

  it "returns open work packages" do
    open_work_package = make_alertable_work_package(status: status_open)
    expect(subject.alertable_for_start).to include(open_work_package)
  end

  it "does not return closed work packages" do
    make_alertable_work_package(status: status_closed)
    expect(subject.alertable_for_start).to be_empty
  end

  ### user involved

  it "returns work packages the user is assigned to" do
    assigned_work_package = make_alertable_work_package(assigned_to: user)
    expect(subject.alertable_for_start).to include(assigned_work_package)
  end

  it "returns work packages the user is responsible / accountable for" do
    accountable_work_package = make_alertable_work_package(responsible: user)
    expect(subject.alertable_for_start).to include(accountable_work_package)
  end

  it "returns work packages the user is watching" do
    watched_work_package = make_alertable_work_package(assigned_to: nil)
    create(:watcher, watchable: watched_work_package, user:)
    expect(subject.alertable_for_start).to include(watched_work_package)
  end

  it "does not return work packages the user is author of" do
    make_alertable_work_package(author: user, assigned_to: nil)
    expect(subject.alertable_for_start).to be_empty
  end

  it "does not return work packages other users are involved into" do
    make_alertable_work_package(assigned_to: other_user)
    expect(subject.alertable_for_start).to be_empty
  end

  ### default notification settings

  context "with default global notification settings" do
    it "returns work packages starting in 1 day for a user" do
      wp_start_in_1_day = make_alertable_work_package(start_date: in_1_day, due_date: nil)
      expect(subject.alertable_for_start).to include(wp_start_in_1_day)
    end

    it "returns work packages due in 1 day for a user" do
      wp_due_in_1_day = make_alertable_work_package(start_date: nil, due_date: in_1_day)
      expect(subject.alertable_for_due).to include(wp_due_in_1_day)
    end

    it "does not return overdue work packages for a user" do
      make_alertable_work_package(start_date: nil, due_date: yesterday)
      expect(subject.alertable_for_due).to be_empty
    end
  end

  ### start_date specs

  shared_examples "alertable if start date" do |days_from_now:|
    date = Date.current + days_from_now.days

    it "returns work packages with start date being #{relative_days(days_from_now)}" do
      work_package = make_alertable_work_package(start_date: date, due_date: nil)
      expect(subject.alertable_for_start).to include(work_package)
    end
  end

  shared_examples "not alertable if start date" do |days_from_now:|
    date = Date.current + days_from_now.days

    it "does not return work packages with start date being #{relative_days(days_from_now)}" do
      make_alertable_work_package(start_date: date, due_date: nil)
      expect(subject.alertable_for_start).to be_empty
    end
  end

  context "with notification settings start_date not set" do
    before do
      global_notification_settings.update(start_date: nil, due_date: nil, overdue: nil)
    end

    include_examples "not alertable if start date", days_from_now: 0
    include_examples "not alertable if start date", days_from_now: 1
    include_examples "not alertable if start date", days_from_now: 3
    include_examples "not alertable if start date", days_from_now: 42
  end

  context "with notification settings start_date set to same day" do
    before do
      global_notification_settings.update(start_date: 0, due_date: nil, overdue: nil)
    end

    include_examples "alertable if start date", days_from_now: 0
    include_examples "not alertable if start date", days_from_now: 1
    include_examples "not alertable if start date", days_from_now: 3
    include_examples "not alertable if start date", days_from_now: 7
  end

  context "with notification settings start_date set to 1 day" do
    before do
      global_notification_settings.update(start_date: 1, due_date: nil, overdue: nil)
    end

    include_examples "not alertable if start date", days_from_now: 0
    include_examples "alertable if start date", days_from_now: 1
    include_examples "not alertable if start date", days_from_now: 3
    include_examples "not alertable if start date", days_from_now: 7
  end

  context "with notification settings start_date set to 3 days" do
    before do
      global_notification_settings.update(start_date: 3, due_date: nil, overdue: nil)
    end

    include_examples "not alertable if start date", days_from_now: 0
    include_examples "not alertable if start date", days_from_now: 1
    include_examples "alertable if start date", days_from_now: 3
    include_examples "not alertable if start date", days_from_now: 7
  end

  context "with notification settings start_date set to 7 days" do
    before do
      global_notification_settings.update(start_date: 7, due_date: nil, overdue: nil)
    end

    include_examples "not alertable if start date", days_from_now: 0
    include_examples "not alertable if start date", days_from_now: 1
    include_examples "not alertable if start date", days_from_now: 3
    include_examples "alertable if start date", days_from_now: 7
  end

  ### due_date specs

  shared_examples "alertable if due date" do |days_from_now:|
    date = Date.current + days_from_now.days

    it "returns work packages with due date being #{relative_days(days_from_now)}" do
      work_package = make_alertable_work_package(start_date: nil, due_date: date)
      expect(subject.alertable_for_due).to include(work_package)
    end
  end

  shared_examples "not alertable if due date" do |days_from_now:|
    date = Date.current + days_from_now.days

    it "does not return work packages with due date being #{relative_days(days_from_now)}" do
      make_alertable_work_package(start_date: nil, due_date: date)
      expect(subject.alertable_for_due).to be_empty
    end
  end

  context "with notification settings due_date not set" do
    before do
      global_notification_settings.update(start_date: nil, due_date: nil, overdue: nil)
    end

    include_examples "not alertable if due date", days_from_now: 0
    include_examples "not alertable if due date", days_from_now: 1
    include_examples "not alertable if due date", days_from_now: 3
    include_examples "not alertable if due date", days_from_now: 42
  end

  context "with notification settings due_date set to same day" do
    before do
      global_notification_settings.update(start_date: nil, due_date: 0, overdue: nil)
    end

    include_examples "alertable if due date", days_from_now: 0
    include_examples "not alertable if due date", days_from_now: 1
    include_examples "not alertable if due date", days_from_now: 3
    include_examples "not alertable if due date", days_from_now: 7
  end

  context "with notification settings due_date set to 1 day" do
    before do
      global_notification_settings.update(start_date: nil, due_date: 1, overdue: nil)
    end

    include_examples "not alertable if due date", days_from_now: 0
    include_examples "alertable if due date", days_from_now: 1
    include_examples "not alertable if due date", days_from_now: 3
    include_examples "not alertable if due date", days_from_now: 7
  end

  context "with notification settings due_date set to 3 days" do
    before do
      global_notification_settings.update(start_date: nil, due_date: 3, overdue: nil)
    end

    include_examples "not alertable if due date", days_from_now: 0
    include_examples "not alertable if due date", days_from_now: 1
    include_examples "alertable if due date", days_from_now: 3
    include_examples "not alertable if due date", days_from_now: 7
  end

  context "with notification settings due_date set to 7 days" do
    before do
      global_notification_settings.update(start_date: nil, due_date: 7, overdue: nil)
    end

    include_examples "not alertable if due date", days_from_now: 0
    include_examples "not alertable if due date", days_from_now: 1
    include_examples "not alertable if due date", days_from_now: 3
    include_examples "alertable if due date", days_from_now: 7
  end

  ### overdue specs

  shared_examples "alertable if due" do |days_ago:|
    date = Date.current - days_ago.days

    it "returns work packages due #{relative_days(-days_ago)}" do
      work_package = make_alertable_work_package(start_date: nil, due_date: date)
      expect(subject.alertable_for_due).to include(work_package)
    end
  end

  shared_examples "not alertable if due" do |days_ago:|
    date = Date.current - days_ago.days

    it "does not return work packages due #{relative_days(-days_ago)}" do
      make_alertable_work_package(start_date: nil, due_date: date)
      expect(subject.alertable_for_due).to be_empty
    end
  end

  context "with notification settings overdue not set" do
    before do
      global_notification_settings.update(start_date: nil, due_date: nil, overdue: nil)
    end

    include_examples "not alertable if due", days_ago: 0
    include_examples "not alertable if due", days_ago: 1
    include_examples "not alertable if due", days_ago: 2
    include_examples "not alertable if due", days_ago: 3
    include_examples "not alertable if due", days_ago: 42
  end

  context "with notification settings overdue set to every day" do
    before do
      global_notification_settings.update(start_date: nil, due_date: nil, overdue: 1)
    end

    include_examples "not alertable if due", days_ago: 0
    include_examples "alertable if due", days_ago: 1
    include_examples "alertable if due", days_ago: 2
    include_examples "alertable if due", days_ago: 10
  end

  context "with notification settings overdue set to every 3 days" do
    before do
      global_notification_settings.update(start_date: nil, due_date: nil, overdue: 3)
    end

    include_examples "not alertable if due", days_ago: 0
    include_examples "alertable if due", days_ago: 1
    include_examples "not alertable if due", days_ago: 2
    include_examples "not alertable if due", days_ago: 3
    include_examples "alertable if due", days_ago: 4
    include_examples "not alertable if due", days_ago: 5
    include_examples "not alertable if due", days_ago: 6
    include_examples "alertable if due", days_ago: 7
  end

  context "with notification settings overdue set to every 7 days" do
    before do
      global_notification_settings.update(start_date: nil, due_date: nil, overdue: 7)
    end

    include_examples "not alertable if due", days_ago: 0
    include_examples "alertable if due", days_ago: 1
    include_examples "not alertable if due", days_ago: 2
    include_examples "not alertable if due", days_ago: 3
    include_examples "not alertable if due", days_ago: 4
    include_examples "not alertable if due", days_ago: 7
    include_examples "alertable if due", days_ago: 8
    include_examples "not alertable if due", days_ago: 12
    include_examples "alertable if due", days_ago: 15
  end

  ### project-specific notification settings specs

  context "with project notification settings overriding global notification settings" do
    shared_let(:project_notification_settings) { user.notification_settings.create(project:) }

    it "uses the project settings" do
      global_notification_settings.update(start_date: nil, due_date: nil, overdue: nil)
      project_notification_settings.update(start_date: 1, due_date: 1, overdue: 1)

      wp_start_and_due_in_1_day =
        make_alertable_work_package(start_date: in_1_day, due_date: in_1_day, project:)
      wp_overdue =
        make_alertable_work_package(start_date: nil, due_date: yesterday, project:)
      wp_start_and_due_in_1_day_other_project =
        make_alertable_work_package(start_date: in_1_day, due_date: in_1_day, project: other_project)

      expect(subject.alertable_for_start).to include(wp_start_and_due_in_1_day)
      expect(subject.alertable_for_due).to include(wp_start_and_due_in_1_day, wp_overdue)

      expect(subject.alertable_for_start).not_to include(wp_start_and_due_in_1_day_other_project)
      expect(subject.alertable_for_due).not_to include(wp_start_and_due_in_1_day_other_project)
    end

    it "does not use global settings if project settings are nil" do
      global_notification_settings.update(start_date: 1, due_date: 1)
      project_notification_settings.update(start_date: nil, due_date: nil)

      make_alertable_work_package(start_date: in_1_day, due_date: in_1_day, project:)

      expect(subject.alertable_for_start).to be_empty
      expect(subject.alertable_for_due).to be_empty
    end
  end
end
