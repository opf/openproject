#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require 'spec_helper'
require 'features/page_objects/notification'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/shared_contexts'
require 'support/edit_fields/edit_field'
require 'features/work_packages/work_packages_page'

describe 'date inplace editor',
         with_settings: { date_format: '%Y-%m-%d' },
         js: true, selenium: true do
  let(:project) { create :project_with_types, public: true }
  let(:work_package) { create :work_package, project:, start_date: Date.parse('2016-01-02') }
  let(:user) { create :admin }
  let(:work_packages_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new }

  let(:start_date) { work_packages_page.edit_field(:combinedDate) }

  before do
    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
  end

  it 'can directly set the due date when only a start date is set' do
    start_date.activate!
    start_date.expect_active!

    start_date.datepicker.expect_year '2016'
    start_date.datepicker.expect_month 'January', true
    start_date.datepicker.select_day '25'

    start_date.save!
    start_date.expect_inactive!
    start_date.expect_state_text '2016-01-02 - 2016-01-25'
  end

  it 'reverses the dates if the selected date is before the current start date' do
    start_date.activate!
    start_date.expect_active!

    start_date.datepicker.expect_year '2016'
    start_date.datepicker.expect_month 'January', true
    start_date.datepicker.select_day '1'

    start_date.save!
    start_date.expect_inactive!
    start_date.expect_state_text '2016-01-01 - 2016-01-02'
  end

  it 'can set "today" as a date via the provided link' do
    start_date.activate!
    start_date.expect_active!

    start_date.click_today

    start_date.datepicker.expect_year Time.zone.today.year
    start_date.datepicker.expect_month Time.zone.today.strftime("%B"), true
    start_date.datepicker.expect_day Time.zone.today.day

    start_date.save!
    start_date.expect_inactive!
    start_date.expect_state_text "#{Time.zone.today.strftime('%Y-%m-%d')} - no finish date"
  end

  context 'with start and end date set' do
    let(:work_package) do
      create :work_package,
             project:,
             start_date: Date.parse('2016-01-02'),
             due_date: Date.parse('2016-01-25')
    end

    it 'selecting a date before the current start date will change the start date' do
      start_date.activate!
      start_date.expect_active!

      start_date.datepicker.expect_year '2016'
      start_date.datepicker.expect_month 'January', true
      start_date.datepicker.select_day '1'

      start_date.save!
      start_date.expect_inactive!
      start_date.expect_state_text '2016-01-01 - 2016-01-25'
    end

    it 'selecting a date in between changes the date that is currently in focus' do
      start_date.activate!
      start_date.expect_active!

      start_date.datepicker.expect_year '2016'
      start_date.datepicker.expect_month 'January', true
      start_date.datepicker.select_day '3'

      # Since the focus shifts automatically, we can directly click again to modify the end date
      start_date.datepicker.select_day '21'

      start_date.save!
      start_date.expect_inactive!
      start_date.expect_state_text '2016-01-03 - 2016-01-21'
    end

    it 'selecting a date after the current finish date will change either start or finish depending on the focus' do
      start_date.activate!
      start_date.expect_active!

      start_date.datepicker.expect_year '2016'
      start_date.datepicker.expect_month 'January', true

      # Focus the end date field
      start_date.activate_due_date_within_modal
      start_date.datepicker.set_date '2016-03-01', true

      # Since the end date is focused, the date will become the new end date
      start_date.save!
      start_date.expect_inactive!
      start_date.expect_state_text '2016-01-02 - 2016-03-01'

      # Activating again and now changing the start date to something after the current end date
      start_date.activate!
      start_date.expect_active!

      start_date.datepicker.expect_year '2016'
      start_date.datepicker.expect_month 'January', true
      start_date.datepicker.set_date '2016-04-01', true

      # This will set the new start and unset the end date
      start_date.save!
      start_date.expect_inactive!
      start_date.expect_state_text '2016-04-01 - no finish date'
    end
  end

  context 'with the start date empty' do
    let(:work_package) { create :work_package, project:, start_date: nil }

    it 'can set "today" as a date via the provided link' do
      start_date.activate!
      start_date.expect_active!

      start_date.click_today

      start_date.datepicker.expect_year Time.zone.today.year
      start_date.datepicker.expect_month Time.zone.today.strftime("%B"), true
      start_date.datepicker.expect_day Time.zone.today.day

      start_date.save!
      start_date.expect_inactive!
      start_date.expect_state_text "#{Time.zone.today.strftime('%Y-%m-%d')} - no finish date"
    end
  end

  it 'can set start and due date to the same day' do
    start_date.activate!
    start_date.expect_active!

    # Set the due date
    start_date.datepicker.set_date Time.zone.today, true
    # As the to be selected date is automatically toggled,
    # we can directly set the start date afterwards to the same day
    start_date.datepicker.set_date Time.zone.today, true

    start_date.save!
    start_date.expect_inactive!
    start_date.expect_state_text "#{Time.zone.today.strftime('%Y-%m-%d')} - #{Time.zone.today.strftime('%Y-%m-%d')}"
  end

  it 'saves the date when clearing and then confirming' do
    start_date.activate!

    sleep 1

    start_date.input_element.click
    start_date.clear with_backspace: true
    start_date.input_element.send_keys :backspace

    start_date.save!

    work_packages_page.expect_and_dismiss_toaster message: 'Successful update.'

    start_date.expect_inactive!
    start_date.expect_state_text 'no start date'

    work_package.reload
    expect(work_package.start_date).to be_nil
  end

  it 'closes the date picker when moving away' do
    wp_table.visit!
    wp_table.open_full_screen_by_doubleclick work_package

    start_date.activate!
    start_date.expect_active!

    page.execute_script('window.history.back()')
    work_packages_page.accept_alert_dialog! if work_packages_page.has_alert_dialog?

    # Ensure no modal survives
    expect(page).to have_no_selector('.op-modal')
  end

  context 'with a date custom field' do
    let!(:type) { create :type }
    let!(:project) { create :project, types: [type] }
    let!(:priority) { create :default_priority }
    let!(:status) { create :default_status }

    let!(:date_cf) do
      create(
        :date_wp_custom_field,
        name: "My date",
        types: [type],
        projects: [project]
      )
    end

    let(:cf_field) { EditField.new page, :"customField#{date_cf.id}" }
    let(:datepicker) { ::Components::Datepicker.new }
    let(:create_page) { ::Pages::FullWorkPackageCreate.new(project:) }

    it 'can handle creating a CF date' do
      create_page.visit!

      type_field = create_page.edit_field(:type)
      type_field.activate!
      type_field.set_value type.name

      cf_field.expect_active!

      # When cancelling, expect there to be no notification
      create_page.cancel!
      create_page.expect_no_toaster type: nil

      create_page.visit!
      cf_field.expect_active!

      # Open date picker
      cf_field.input_element.click
      datepicker.set_date Time.zone.today

      create_page.edit_field(:subject).set_value 'My subject!'
      create_page.save!
      create_page.expect_and_dismiss_toaster message: 'Successful creation'

      wp = WorkPackage.last
      expect(wp.custom_value_for(date_cf.id).value).to eq Time.zone.today.iso8601
    end
  end

  context 'with the work package having no relations whatsoever' do
    let!(:work_package) { create :work_package, project: }

    before do
      start_date.activate!
      start_date.expect_active!
    end

    it 'does not show a banner with or without manual scheduling' do
      expect(page).to have_no_selector('[data-qa-selector="op-modal-banner-warning"]')
      expect(page).to have_no_selector('[data-qa-selector="op-modal-banner-info"]')

      # When toggling manuallly scheduled
      start_date.expect_scheduling_mode manually: false
      start_date.toggle_scheduling_mode
      start_date.expect_scheduling_mode manually: true

      expect(page).to have_no_selector('[data-qa-selector="op-modal-banner-warning"]')
      expect(page).to have_no_selector('[data-qa-selector="op-modal-banner-info"]')
    end
  end

  context 'with the work package being a parent' do
    let!(:child) { create :work_package, project:, start_date: 1.day.ago, due_date: 5.days.from_now }
    let!(:work_package) do
      wp = create :work_package, project: project, schedule_manually: schedule_manually
      child.update! parent: wp
      wp
    end

    before do
      start_date.activate!
      start_date.expect_active!
    end

    context 'when parent is manually scheduled' do
      let(:schedule_manually) { true }

      it 'shows a banner that the relations are ignored' do
        expect(page).to have_selector('[data-qa-selector="op-modal-banner-warning"] span',
                                      text: 'Manual scheduling enabled, all relations ignored.')

        # When toggling manuallly scheduled
        start_date.expect_scheduling_mode manually: true
        start_date.toggle_scheduling_mode
        start_date.expect_scheduling_mode manually: false

        # Expect banner to switch
        expect(page).to have_selector('[data-qa-selector="op-modal-banner-info"] span',
                                      text: 'Automatically scheduled. Dates are derived from relations.')

        new_window = window_opened_by { click_on 'Show relations' }
        switch_to_window new_window

        wp_table.expect_work_package_listed child
        wp_timeline.expect_timeline!
      end
    end

    context 'when parent is not manually scheduled' do
      let(:schedule_manually) { false }

      it 'shows a banner that the dates are not editable' do
        expect(page).to have_selector('[data-qa-selector="op-modal-banner-info"] span',
                                      text: 'Automatically scheduled. Dates are derived from relations.')

        # When toggling manuallly scheduled
        start_date.expect_scheduling_mode manually: false
        start_date.toggle_scheduling_mode
        start_date.expect_scheduling_mode manually: true

        expect(page).to have_selector('[data-qa-selector="op-modal-banner-warning"] span',
                                      text: 'Manual scheduling enabled, all relations ignored.')

        new_window = window_opened_by { click_on 'Show relations' }
        switch_to_window new_window

        wp_table.expect_work_package_listed child
        wp_timeline.expect_timeline!
      end
    end
  end

  context 'with the work package having a precedes relation' do
    let!(:work_package) { create :work_package, project:, schedule_manually: }
    let!(:preceding) { create :work_package, project:, start_date: 10.days.ago, due_date: 5.days.ago }

    let!(:relationship) do
      create :relation,
             from: preceding,
             to: work_package,
             relation_type: Relation::TYPE_PRECEDES
    end

    before do
      start_date.activate!
      start_date.expect_active!
    end

    context 'when work package is manually scheduled' do
      let(:schedule_manually) { true }

      it 'shows a banner that the relations are ignored' do
        expect(page).to have_selector('[data-qa-selector="op-modal-banner-warning"] span',
                                      text: 'Manual scheduling enabled, all relations ignored.')

        # When toggling manuallly scheduled
        start_date.expect_scheduling_mode manually: true
        start_date.toggle_scheduling_mode
        start_date.expect_scheduling_mode manually: false

        # Expect new banner info
        expect(page).to have_selector('[data-qa-selector="op-modal-banner-info"] span',
                                      text: 'Available start date is limited by relations.')

        new_window = window_opened_by { click_on 'Show relations' }
        switch_to_window new_window

        wp_table.expect_work_package_listed preceding
        wp_timeline.expect_timeline!
      end
    end

    context 'when work package is not manually scheduled' do
      let(:schedule_manually) { false }

      it 'shows a banner that the start date is limited' do
        expect(page).to have_selector('[data-qa-selector="op-modal-banner-info"] span',
                                      text: 'Available start date is limited by relations.')

        # When toggling manuallly scheduled
        start_date.expect_scheduling_mode manually: false
        start_date.toggle_scheduling_mode
        start_date.expect_scheduling_mode manually: true

        expect(page).to have_selector('[data-qa-selector="op-modal-banner-warning"] span',
                                      text: 'Manual scheduling enabled, all relations ignored.')
      end
    end
  end

  context 'with the work package having a follows relation' do
    let!(:work_package) { create :work_package, project:, schedule_manually: }
    let!(:following) { create :work_package, project:, start_date: 5.days.from_now, due_date: 10.days.from_now }

    let!(:relationship) do
      create :relation,
             from: following,
             to: work_package,
             relation_type: Relation::TYPE_FOLLOWS
    end

    before do
      start_date.activate!
      start_date.expect_active!
    end

    context 'when work package is manually scheduled' do
      let(:schedule_manually) { true }

      it 'shows a banner that the relations are ignored' do
        expect(page).to have_selector('[data-qa-selector="op-modal-banner-warning"] span',
                                      text: 'Manual scheduling enabled, all relations ignored.')

        # When toggling manuallly scheduled
        start_date.expect_scheduling_mode manually: true
        start_date.toggle_scheduling_mode
        start_date.expect_scheduling_mode manually: false

        expect(page).to have_selector('[data-qa-selector="op-modal-banner-info"] span',
                                      text: 'Changing these dates will affect dates of related work packages.')

        new_window = window_opened_by { click_on 'Show relations' }
        switch_to_window new_window

        wp_table.expect_work_package_listed following
        wp_timeline.expect_timeline!
      end
    end

    context 'when work package is not manually scheduled' do
      let(:schedule_manually) { false }

      it 'shows a banner that the start date is limited' do
        expect(page).to have_selector('[data-qa-selector="op-modal-banner-info"] span',
                                      text: 'Changing these dates will affect dates of related work packages.')

        # When toggling manuallly scheduled
        start_date.expect_scheduling_mode manually: false
        start_date.toggle_scheduling_mode
        start_date.expect_scheduling_mode manually: true

        expect(page).to have_selector('[data-qa-selector="op-modal-banner-warning"] span',
                                      text: 'Manual scheduling enabled, all relations ignored.')
      end
    end
  end
end
