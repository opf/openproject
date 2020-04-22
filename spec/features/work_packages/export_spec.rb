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
    wp_1
    wp_2
    wp_3
    wp_4

    login_as(current_user)
  end

  let(:export_type) { 'CSV' }
  subject { DownloadedFile.download_content }

  def export!(wait_for_downloads = true)
    DownloadedFile::clear_downloads

    work_packages_page.ensure_loaded

    settings_menu.open_and_choose 'Export ...'
    click_on export_type

    begin
      perform_enqueued_jobs
    rescue
      # nothing
    end


    if wait_for_downloads
      # Wait for the file to download
      ::DownloadedFile.wait_for_download
      ::DownloadedFile.wait_for_download_content
    end
  end

  after do
    DownloadedFile::clear_downloads
  end

  context 'CSV export' do
    context 'with default filter' do
      before do
        work_packages_page.visit_index
        filters.expect_filter_count 1
        filters.open
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
         js: true, retry: 2 do
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

      it 'shows only work packages of the filtered type', js: true, retry: 2 do
        filters.add_filter_by 'Type', 'is', wp_3.type.name

        expect(page).to have_no_content(wp_2.description) # safeguard

        export!

        expect(subject).not_to have_text(wp_1.description)
        expect(subject).not_to have_text(wp_2.description)
        expect(subject).to have_text(wp_3.description)
      end

      it 'exports selected columns', js: true, retry: 2 do
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
          .not_to have_content I18n.t('js.label_export_preparing')

        expect(page)
          .to have_content I18n.t(:error_pdf_export_too_many_columns)
      end
    end
  end
end
