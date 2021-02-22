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
require 'features/work_packages/work_packages_page'

describe 'work package export', type: :feature do
  let(:project) { FactoryBot.create :project_with_types, types: [type_a, type_b] }
  let(:current_user) { FactoryBot.create :admin }

  let(:type_a) { FactoryBot.create :type, name: "Type A" }
  let(:type_b) { FactoryBot.create :type, name: "Type B" }

  let(:wp_1) { FactoryBot.create :work_package, project: project, done_ratio: 25, type: type_a }
  let(:wp_2) { FactoryBot.create :work_package, project: project, done_ratio: 0, type: type_a }
  let(:wp_3) { FactoryBot.create :work_package, project: project, done_ratio: 0, type: type_b }
  let(:wp_4) { FactoryBot.create :work_package, project: project, done_ratio: 0, type: type_a }

  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { ::Components::WorkPackages::Columns.new }
  let(:filters) { ::Components::WorkPackages::Filters.new }
  let(:group_by) { ::Components::WorkPackages::GroupBy.new }
  let(:hierarchies) { ::Components::WorkPackages::Hierarchies.new }
  let(:settings_menu) { ::Components::WorkPackages::SettingsMenu.new }

  before do
    @download_list = DownloadList.new
    wp_1
    wp_2
    wp_3
    wp_4

    login_as(current_user)
  end

  let(:export_type) { 'CSV' }
  subject { @download_list.refresh_from(page).latest_downloaded_content }

  def export!(expect_success = true)
    work_packages_page.ensure_loaded

    settings_menu.open_and_choose 'Export ...'
    click_on export_type

    # Expect to get a response regarding queuing
    expect(page).to have_content I18n.t('js.job_status.generic_messages.in_queue'),
                                 wait: 10

    # Expect title
    expect(page).to have_selector 'h1', text: I18n.t('export.your_work_packages_export')

    begin
      perform_enqueued_jobs
    rescue StandardError
      # nothing
    end

    if expect_success
      expect(page).to have_text("The export has completed successfully")
    end
  end

  after do
    DownloadList.clear
  end

  context 'CSV export' do
    context 'with default filter' do
      before do
        work_packages_page.visit_index
        filters.expect_filter_count 1
        filters.open
      end

      it 'shows all work packages with the default filters', js: true do
        export!

        expect(subject).to have_text(wp_1.description)
        expect(subject).to have_text(wp_2.description)
        expect(subject).to have_text(wp_3.description)
        expect(subject).to have_text(wp_4.description)

        # results are ordered by ID (asc) and not grouped by type
        expect(subject.scan(/Type (A|B)/).flatten).to eq %w(A A B A)
      end

      it 'shows all work packages grouped by ', js: true do
        group_by.enable_via_menu 'Type'

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
         js: true do
        filters.add_filter_by 'Progress (%)', 'is', ['25'], 'percentageDone'

        sleep 1
        loading_indicator_saveguard

        wp_table.expect_work_package_listed(wp_1)
        wp_table.ensure_work_package_not_listed!(wp_2, wp_3)

        export!

        expect(subject).to have_text(wp_1.description)
        expect(subject).not_to have_text(wp_2.description)
        expect(subject).not_to have_text(wp_3.description)
      end

      it 'shows only work packages of the filtered type', js: true do
        filters.add_filter_by 'Type', 'is', wp_3.type.name

        expect(page).to have_no_content(wp_2.description) # safeguard

        sleep(0.5)

        export!

        expect(subject).not_to have_text(wp_1.description)
        expect(subject).not_to have_text(wp_2.description)
        expect(subject).to have_text(wp_3.description)
      end

      it 'exports selected columns', js: true do
        columns.add 'Progress (%)'

        export!

        expect(subject).to have_text('Progress (%)')
        expect(subject).to have_text('25')
      end
    end

    describe 'with a manually sorted query', js: true do
      let(:query) do
        FactoryBot.create :query,
                          user: current_user,
                          project: project
      end

      before do
        ::OrderedWorkPackage.create(query: query, work_package: wp_4, position: 0)
        ::OrderedWorkPackage.create(query: query, work_package: wp_1, position: 1)
        ::OrderedWorkPackage.create(query: query, work_package: wp_2, position: 2)
        ::OrderedWorkPackage.create(query: query, work_package: wp_3, position: 3)

        query.add_filter('manual_sort', 'ow', [])
        query.sort_criteria = [[:manual_sorting, 'asc']]
        query.save!
      end

      it 'returns the correct number of work packages' do
        wp_table.visit_query query
        wp_table.expect_work_package_listed(wp_1, wp_2, wp_3, wp_4)
        wp_table.expect_work_package_order(wp_4, wp_1, wp_2, wp_3)

        export!

        expect(page).to have_selector('.job-status--modal .icon-checkmark', wait: 10)
        expect(page).to have_content('The export has completed successfully.')

        expect(subject).to have_text(wp_1.description)
        expect(subject).to have_text(wp_2.description)
        expect(subject).to have_text(wp_3.description)
        expect(subject).to have_text(wp_4.description)

        # results are ordered by ID (asc) and not grouped by type
        expect(subject.scan(/WorkPackage No\. \d+,/)).to eq [wp_4, wp_1, wp_2, wp_3].map { |wp| wp.subject + ',' }
      end
    end
  end

  context 'PDF export', js: true do
    let(:export_type) { 'PDF' }
    let(:query) do
      FactoryBot.create :query,
                        user: current_user,
                        project: project
    end

    context 'with many columns' do
      before do
        query.column_names = query.available_columns.map { |c| c.name.to_s } - ['bcf_thumbnail']
        query.save!

        # Despite attempts to provoke the error by having a lot of columns, the pdf
        # is still being drawn successfully. We thus have to fake the error.
        allow_any_instance_of(WorkPackage::PDFExport::WorkPackageListToPdf)
          .to receive(:render!)
          .and_return(WorkPackage::Exporter::Result::Error.new(I18n.t(:error_pdf_export_too_many_columns)))
      end

      it 'returns the error' do
        wp_table.visit_query query

        export!(false)

        expect(page)
          .to have_content(I18n.t(:error_pdf_export_too_many_columns), wait: 10)
      end
    end
  end

  # Atom exports are not downloaded. In fact, it is not even a download but rather
  # a feed one can follow.
  context 'Atom export', js: true do
    let(:export_type) { 'Atom' }
    context 'with default filter' do
      before do
        work_packages_page.visit_index
        filters.expect_filter_count 1
        filters.open
      end

      it 'shows an xml with work packages' do
        settings_menu.open_and_choose 'Export ...'

        # The feed is opened in a new tab
        new_window = window_opened_by { click_on export_type }

        within_window new_window do
          expect(page).to have_text(wp_1.description)
          expect(page).to have_text(wp_2.description)
          expect(page).to have_text(wp_3.description)
          expect(page).to have_text(wp_4.description)
        end
      end
    end
  end
end
