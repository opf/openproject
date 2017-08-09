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
require 'features/work_packages/work_packages_page'

describe 'work package export', type: :feature do
  let(:project) { FactoryGirl.create :project_with_types, types: [type_a, type_b] }
  let(:current_user) { FactoryGirl.create :admin }

  let(:type_a) { FactoryGirl.create :type, name: "Type A" }
  let(:type_b) { FactoryGirl.create :type, name: "Type B" }

  let(:wp_1) { FactoryGirl.create :work_package, project: project, done_ratio: 25, type: type_a }
  let(:wp_2) { FactoryGirl.create :work_package, project: project, done_ratio: 0, type: type_a }
  let(:wp_3) { FactoryGirl.create :work_package, project: project, done_ratio: 0, type: type_b }
  let(:wp_4) { FactoryGirl.create :work_package, project: project, done_ratio: 0, type: type_a }

  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  before do
    wp_1
    wp_2
    wp_3
    wp_4

    allow(User).to receive(:current).and_return current_user
  end

  subject { DownloadedFile.download_content }

  def export!
    DownloadedFile::clear_downloads

    work_packages_page.ensure_loaded
    work_packages_page.open_settings!

    click_on 'Export ...'
    click_on 'CSV'
  end

  before do
    work_packages_page.visit_index
    work_packages_page.click_toolbar_button 'Activate Filter'

    # render the CSV as plain text so we can run expectations against the output
    expect_any_instance_of(WorkPackagesController)
      .to receive(:send_data) do |receiver, serialized_work_packages, _opts|
        receiver.render plain: serialized_work_packages
      end
  end

  after do
    DownloadedFile::clear_downloads
  end

  it 'shows all work packages with the default filters', js: true, retry: 2 do
    export!

    expect(subject).to have_text(wp_1.description)
    expect(subject).to have_text(wp_2.description)
    expect(subject).to have_text(wp_3.description)
    expect(subject).to have_text(wp_4.description)

    # results are ordered by ID (asc) and not grouped by type
    expect(subject.scan(/Type (A|B)/).flatten).to eq %w(A A B A)
  end

  it 'shows all work packages grouped by ', js: true, retry: 2 do
    work_packages_page.open_settings!
    click_on 'Hide hierarchy'

    work_packages_page.open_settings!
    click_on 'Group by ...'
    select 'Type', from: 'selected_columns_new'
    click_on 'Apply'

    wp_table.expect_work_package_listed(wp_1)
    wp_table.expect_work_package_listed(wp_2)
    wp_table.expect_work_package_listed(wp_3)
    wp_table.expect_work_package_listed(wp_4)

    export!

    expect(subject).to have_text(wp_1.description)
    expect(subject).to have_text(wp_2.description)
    expect(subject).to have_text(wp_3.description)
    expect(subject).to have_text(wp_4.description)

    # grouped by type
    expect(subject.scan(/Type (A|B)/).flatten).to eq %w(A A A B)
  end

  it 'shows only the work package with the right progress if filtered this way',
     js: true, retry: 2 do
    select 'Progress (%)', from: 'add_filter_select'
    fill_in 'values-percentageDone', with: '25'

    wp_table.expect_work_package_listed(wp_1)
    wp_table.expect_work_package_not_listed(wp_2, wp_3)

    export!

    expect(subject).to have_text(wp_1.description)
    expect(subject).not_to have_text(wp_2.description)
    expect(subject).not_to have_text(wp_3.description)
  end

  it 'shows only work packages of the filtered type', js: true, retry: 2 do
    select 'Type', from: 'add_filter_select'
    select wp_3.type.name, from: 'values-type'

    expect(page).to have_no_content(wp_2.description) # safeguard

    export!

    expect(subject).not_to have_text(wp_1.description)
    expect(subject).not_to have_text(wp_2.description)
    expect(subject).to have_text(wp_3.description)
  end

  it 'exports selected columns', js: true, retry: 2 do
    work_packages_page.add_column! 'Progress (%)'

    export!

    expect(subject).to have_text('Progress (%)')
    expect(subject).to have_text('25')
  end
end
