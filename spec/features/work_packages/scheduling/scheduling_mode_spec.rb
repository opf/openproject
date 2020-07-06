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
    FactoryBot.create(:work_package, project: project, start_date: '2016-01-06', due_date: '2016-01-10').tap do |pre|
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

  before do
    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
  end

  it 'can toggle the scheduling mode through the date modal' do
    expect(wp.schedule_manually).to eq false
    combined_field.activate!
    combined_field.expect_active!

    combined_field.expect_scheduling_mode manually: false
    combined_field.toggle_scheduling_mode
    combined_field.expect_scheduling_mode manually: true

    combined_field.save!
    work_packages_page.expect_and_dismiss_notification message: 'Successful update.'

    work_package.reload
    expect(wp.schedule_manually).to eq true
  end
end
