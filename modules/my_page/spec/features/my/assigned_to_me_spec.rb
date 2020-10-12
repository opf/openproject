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

require_relative '../../support/pages/my/page'

describe 'Assigned to me embedded query on my page', type: :feature, js: true do
  let!(:type) { FactoryBot.create :type }
  let!(:priority) { FactoryBot.create :default_priority }
  let!(:project) { FactoryBot.create :project, types: [type] }
  let!(:open_status) { FactoryBot.create :default_status }
  let!(:assigned_work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      subject: 'Assigned to me',
                      type: type,
                      author: user,
                      assigned_to: user
  end
  let!(:assigned_work_package_2) do
    FactoryBot.create :work_package,
                      project: project,
                      subject: 'My task 2',
                      type: type,
                      author: user,
                      assigned_to: user
  end
  let!(:assigned_to_other_work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      subject: 'Not assigend to me',
                      type: type,
                      author: user,
                      assigned_to: other_user
  end
  let(:other_user) do
    FactoryBot.create(:user)
  end

  let(:role) { FactoryBot.create(:role, permissions: %i[view_work_packages add_work_packages edit_work_packages save_queries]) }

  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:my_page) do
    Pages::My::Page.new
  end
  let(:assigned_area) { Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)') }
  let(:created_area) { Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(2)') }
  let(:embedded_table) { Pages::EmbeddedWorkPackagesTable.new(assigned_area.area) }
  let(:hierarchies) { ::Components::WorkPackages::Hierarchies.new }

  before do
    login_as user
  end

  context 'with parent work package' do
    let!(:assigned_work_package_child) do
      FactoryBot.create :work_package,
                        subject: 'Child',
                        parent: assigned_work_package,
                        project: project,
                        type: type,
                        author: user,
                        assigned_to: user
    end

    it 'can toggle hierarchy mode in embedded tables (Regression test #29578)' do
      my_page.visit!

      # exists as default
      assigned_area.expect_to_exist

      page.within(assigned_area.area) do
        # expect hierarchy in child
        hierarchies.expect_mode_enabled

        hierarchies.expect_hierarchy_at assigned_work_package
        hierarchies.expect_leaf_at assigned_work_package_child

        # toggle parent
        hierarchies.toggle_row assigned_work_package
        hierarchies.expect_hierarchy_at assigned_work_package, collapsed: true

        # disable
        hierarchies.disable_via_header
        hierarchies.expect_no_hierarchies

        sleep(0.2)

        # re-enable
        hierarchies.enable_via_header

        sleep(0.2)

        hierarchies.expect_mode_enabled
        hierarchies.expect_hierarchy_at assigned_work_package, collapsed: true
      end
    end
  end

  it 'can create a new ticket with correct me values (Regression test #28488)' do
    my_page.visit!

    # exists as default
    assigned_area.expect_to_exist

    expect(assigned_area.area)
      .to have_selector('.subject', text: assigned_work_package.subject)

    expect(assigned_area.area)
      .to have_no_selector('.subject', text: assigned_to_other_work_package.subject)

    embedded_table.click_inline_create

    subject_field = embedded_table.edit_field(nil, :subject)
    subject_field.expect_active!

    subject_field.set_value 'Assigned to me'
    subject_field.save!

    # Set project
    project_field = embedded_table.edit_field(nil, :project)
    project_field.expect_active!
    project_field.openSelectField
    project_field.set_value project.name

    # Set type
    type_field = embedded_table.edit_field(nil, :type)
    type_field.expect_active!
    type_field.openSelectField
    type_field.set_value type.name

    embedded_table.expect_notification(
      message: 'Successful creation. Click here to open this work package in fullscreen view.'
    )

    wp = WorkPackage.last
    expect(wp.subject).to eq('Assigned to me')
    expect(wp.assigned_to_id).to eq(user.id)

    embedded_table.expect_work_package_listed wp
  end

  it 'can paginate in embedded tables (Regression test #29845)', with_settings: { per_page_options: '1' } do
    my_page.visit!

    # exists as default
    assigned_area.expect_to_exist

    within assigned_area.area do
      expect(page)
        .to have_selector('.subject', text: assigned_work_package.subject)
      expect(page)
        .not_to have_selector('.subject', text: assigned_work_package_2.subject)

      page.find('.pagination--item a', text: '2').click

      expect(page)
        .not_to have_selector('.subject', text: assigned_work_package.subject)
      expect(page)
        .to have_selector('.subject', text: assigned_work_package_2.subject)
    end

    assigned_area.resize_to(1, 2)

    my_page.expect_notification(message: I18n.t('js.notice_successful_update'))

    assigned_area.expect_to_span(1, 1, 2, 3)
    # has been moved down by resizing
    created_area.expect_to_span(2, 2, 3, 3)
  end
end
