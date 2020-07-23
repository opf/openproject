#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'features/page_objects/notification'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/shared_contexts'
require 'support/edit_fields/edit_field'
require 'features/work_packages/work_packages_page'

describe 'scheduling mode',
         js: true do
  let(:project) { FactoryBot.create :project_with_types, public: true }
  # Constructing a work package graph that looks like this:
  #
  #                   wp_parent       wp_suc_parent
  #                       |                |
  #                     hierarchy       hierarchy
  #                       |                |
  #                       v                v
  # wp_pre <- follows <- wp <- follows - wp_suc
  #                       |                |
  #                    hierarchy        hierarchy
  #                       |               |
  #                       v               v
  #                     wp_child      wp_suc_child
  #
  let!(:wp) { FactoryBot.create :work_package, project: project, start_date: '2016-01-01', due_date: '2016-01-05' }
  let!(:wp_parent) do
    FactoryBot.create(:work_package, project: project, start_date: '2016-01-01', due_date: '2016-01-05').tap do |parent|
      FactoryBot.create(:hierarchy_relation, from: parent, to: wp)
    end
  end
  let!(:wp_child) do
    FactoryBot.create(:work_package, project: project, start_date: '2016-01-01', due_date: '2016-01-05').tap do |child|
      FactoryBot.create(:hierarchy_relation, from: wp, to: child)
    end
  end
  let!(:wp_pre) do
    FactoryBot.create(:work_package, project: project, start_date: '2015-12-15', due_date: '2015-12-31').tap do |pre|
      FactoryBot.create(:follows_relation, from: wp, to: pre)
    end
  end
  let!(:wp_suc) do
    FactoryBot.create(:work_package, project: project, start_date: '2016-01-06', due_date: '2016-01-10').tap do |suc|
      FactoryBot.create(:follows_relation, from: suc, to: wp)
    end
  end
  let!(:wp_suc_parent) do
    FactoryBot.create(:work_package, project: project, start_date: '2016-01-06', due_date: '2016-01-10').tap do |parent|
      FactoryBot.create(:hierarchy_relation, from: parent, to: wp_suc)
    end
  end
  let!(:wp_suc_child) do
    FactoryBot.create(:work_package, project: project, start_date: '2016-01-06', due_date: '2016-01-10').tap do |child|
      FactoryBot.create(:hierarchy_relation, from: wp_suc, to: child)
    end
  end
  let(:user) { FactoryBot.create :admin }
  let(:work_packages_page) { Pages::SplitWorkPackage.new(wp, project) }

  let(:combined_field) { work_packages_page.edit_field(:combinedDate) }

  def expect_dates(work_package, start_date, due_date)
    work_package.reload
    expect(work_package.start_date).to eql Date.parse(start_date)
    expect(work_package.due_date).to eql Date.parse(due_date)
  end

  before do
    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
  end

  it 'can toggle the scheduling mode through the date modal' do
    expect(wp.schedule_manually).to eq false

    # Editing the start/due dates of a parent work package is possible if the
    # work package is manually scheduled
    combined_field.activate!(expect_open: false)
    combined_field.expect_active!
    combined_field.expect_scheduling_mode manually: false
    combined_field.expect_parent_notification
    combined_field.toggle_scheduling_mode
    combined_field.update(%w[2016-01-05 2016-01-10])

    work_packages_page.expect_and_dismiss_notification message: 'Successful update.'

    expect_dates(wp, '2016-01-05', '2016-01-10')
    expect(wp.schedule_manually).to be_truthy

    # is not moved because it is a child
    expect_dates(wp_child, '2016-01-01', '2016-01-05')

    # The due date is moved backwards because its child was moved
    # but the start date remains unchanged as its grandchild stays put.
    expect_dates(wp_parent, '2016-01-01', '2016-01-10')

    # is moved backwards because of the follows relationship
    expect_dates(wp_suc, '2016-01-11', '2016-01-15')

    # is moved backwards because it is the parent of the successor
    expect_dates(wp_suc_parent, '2016-01-11', '2016-01-15')

    # is moved backwards as the whole hierarchy is moved backwards
    expect_dates(wp_suc_child, '2016-01-11', '2016-01-15')

    # Switching back to automatic scheduling will lead to the work package
    # and all work packages that are dependent to be rescheduled again.
    combined_field.activate!(expect_open: false)
    combined_field.expect_active!
    combined_field.expect_scheduling_mode manually: true
    combined_field.toggle_scheduling_mode
    combined_field.expect_parent_notification
    combined_field.save!

    work_packages_page.expect_and_dismiss_notification message: 'Successful update.'

    # Moved forward again as the child determines the dates again
    expect_dates(wp, '2016-01-01', '2016-01-05')
    expect(wp.schedule_manually).to be_falsey

    # Had not been moved in the first place
    expect_dates(wp_child, '2016-01-01', '2016-01-05')

    # As the child now again takes up the same time interval as the grandchild,
    # the interval is shortened again.
    expect_dates(wp_parent, '2016-01-01', '2016-01-05')

    # is moved forward again because of the follows relationship
    expect_dates(wp_suc, '2016-01-06', '2016-01-10')

    # is moved forward again because its child is also moved forward
    expect_dates(wp_suc_parent, '2016-01-06', '2016-01-10')

    # is moved forward again because its parent is also moved forward
    expect_dates(wp_suc_child, '2016-01-06', '2016-01-10')

    # Switching back to manual scheduling but this time forward will lead to the work package
    # and all work packages that are dependent to be rescheduled again.
    combined_field.activate!(expect_open: false)
    combined_field.expect_active!
    combined_field.expect_scheduling_mode manually: false
    combined_field.expect_parent_notification
    combined_field.toggle_scheduling_mode
    # Increasing the duration while at it
    combined_field.update(%w[2015-12-20 2015-12-31])

    work_packages_page.expect_and_dismiss_notification message: 'Successful update.'

    expect_dates(wp, '2015-12-20', '2015-12-31')
    expect(wp.schedule_manually).to be_truthy

    # is not moved because it is a child
    expect_dates(wp_child, '2016-01-01', '2016-01-05')

    # The start date is moved forward because its child was moved
    # but the due date remains unchanged as its grandchild stays put.
    expect_dates(wp_parent, '2015-12-20', '2016-01-05')

    # is moved forward because of the follows relationship
    expect_dates(wp_suc, '2016-01-01', '2016-01-05')

    # is moved forward because it is the parent of the successor
    expect_dates(wp_suc_parent, '2016-01-01', '2016-01-05')

    # is moved forward as the whole hierarchy is moved backwards
    expect_dates(wp_suc_child, '2016-01-01', '2016-01-05')

    # Switching back to automatic scheduling will lead to the work package
    # and all work packages that are dependent to be rescheduled again.
    combined_field.activate!(expect_open: false)
    combined_field.expect_active!
    combined_field.expect_scheduling_mode manually: true
    combined_field.toggle_scheduling_mode
    combined_field.expect_parent_notification
    combined_field.save!

    work_packages_page.expect_and_dismiss_notification message: 'Successful update.'

    # Moved backwards again as the child determines the dates again
    expect_dates(wp, '2016-01-01', '2016-01-05')
    expect(wp.schedule_manually).to be_falsey

    # Had not been moved in the first place
    expect_dates(wp_child, '2016-01-01', '2016-01-05')

    # As the child now again takes up the same time interval as the grandchild,
    # the interval is shortened again.
    expect_dates(wp_parent, '2016-01-01', '2016-01-05')

    # is moved backwards again because of the follows relationship
    expect_dates(wp_suc, '2016-01-06', '2016-01-10')

    # is moved backwards again because its child is also moved forward
    expect_dates(wp_suc_parent, '2016-01-06', '2016-01-10')

    # is moved backwards again because its parent is also moved forward
    expect_dates(wp_suc_child, '2016-01-06', '2016-01-10')
  end
end
