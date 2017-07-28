require 'spec_helper'

describe 'Inline editing work packages', js: true do
  let(:manager_role) do
    FactoryGirl.create :role,
                       permissions: [:view_work_packages,
                                     :edit_work_packages]
  end
  let(:manager) do
    FactoryGirl.create :user,
                       firstname:           'Manager',
                       lastname:            'Guy',
                       member_in_project:   project,
                       member_through_role: manager_role
  end
  let(:type) { FactoryGirl.create :type }
  let(:status1) { FactoryGirl.create :status }
  let(:status2) { FactoryGirl.create :status }

  let(:project) { FactoryGirl.create(:project, types: [type]) }
  let(:work_package) {
    FactoryGirl.create(:work_package,
                       project: project,
                       type:    type,
                       status:  status1,
                       subject: 'Foobar')
  }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let(:workflow) do
    FactoryGirl.create :workflow,
                       type_id:    type.id,
                       old_status: status1,
                       new_status: status2,
                       role:       manager_role
  end
  let(:version) { FactoryGirl.create :version, project: project }
  let(:category) { FactoryGirl.create :category, project: project }

  before do
    login_as(manager)
  end

  context 'simple work package' do
    before do
      work_package
      workflow

      wp_table.visit!
      wp_table.expect_work_package_listed(work_package)
    end

    it 'allows updating and seeing the results' do
      subject_field = wp_table.edit_field(work_package, :subject)
      subject_field.expect_text('Foobar')

      subject_field.activate!

      subject_field.set_value('New subject!')

      expect(UpdateWorkPackageService).to receive(:new).and_call_original
      subject_field.save!
      subject_field.expect_text('New subject!')

      wp_table.expect_notification(
        message: 'Successful update. Click here to open this work package in fullscreen view.'
      )

      work_package.reload
      expect(work_package.subject).to eq('New subject!')
    end

    it 'allows to subsequently edit multiple fields' do
      subject_field = wp_table.edit_field(work_package, :subject)
      status_field  = wp_table.edit_field(work_package, :status)

      subject_field.activate!
      subject_field.set_value('Other subject!')
      subject_field.save!

      wp_table.expect_notification(message: 'Successful update')
      wp_table.dismiss_notification!
      wp_table.expect_no_notification(message: 'Successful update')

      status_field.activate!
      status_field.set_value(status2.name)

      subject_field.expect_inactive!
      status_field.expect_inactive!

      subject_field.expect_text('Other subject!')
      status_field.expect_text(status2.name)

      wp_table.expect_notification(message: 'Successful update')
      wp_table.dismiss_notification!
      wp_table.expect_no_notification(message: 'Successful update')

      work_package.reload
      expect(work_package.subject).to eq('Other subject!')
      expect(work_package.status.id).to eq(status2.id)
    end

    it 'provides error handling' do
      subject_field = wp_table.edit_field(work_package, :subject)
      subject_field.expect_text('Foobar')

      subject_field.activate!

      subject_field.set_value('')
      subject_field.expect_invalid

      expect(UpdateWorkPackageService).not_to receive(:new)
      subject_field.save!
    end
  end

  context 'custom field' do
    let(:custom_fields) {
      fields = [
        FactoryGirl.create(
          :work_package_custom_field,
          field_format:    'list',
          possible_values: %w(foo bar xyz),
          is_required:     true,
          is_for_all:      false
        ),
        FactoryGirl.create(
          :work_package_custom_field,
          field_format: 'string',
          is_required:  true,
          is_for_all:   false
        )
      ]

      fields
    }
    let(:type) { FactoryGirl.create(:type_task, custom_fields: custom_fields) }
    let(:project) { FactoryGirl.create(:project, types: [type]) }
    let(:work_package) {
      FactoryGirl.create(:work_package,
                         subject: 'Foobar',
                         status:  status1,
                         type:    type,
                         project: project)
    }

    before do
      work_package
      workflow

      # Require custom fields for this project
      project.work_package_custom_fields = custom_fields
      project.save!

      wp_table.visit!
      wp_table.expect_work_package_listed(work_package)
    end

    it 'opens required custom fields when not set' do
      subject_field = wp_table.edit_field(work_package, :subject)
      subject_field.expect_text('Foobar')

      subject_field.activate!
      subject_field.set_value('New subject!')
      subject_field.save!

      # Should raise two errors
      cf_list_name = custom_fields.first.name
      cf_text_name = custom_fields.last.name
      wp_table.expect_notification(
        type:    :error,
        message: "#{cf_list_name} can't be blank. #{cf_text_name} can't be blank."
      )

      expect(page).to have_selector('th a', text: cf_list_name.upcase)
      expect(page).to have_selector('th a', text: cf_text_name.upcase)
      expect(wp_table.row(work_package)).to have_selector('.wp-table--cell-container.-error', count: 2)

      cf_text = wp_table.edit_field(work_package, :customField2)
      cf_text.update('my custom text', expect_failure: true)

      cf_list            = wp_table.edit_field(work_package, :customField1)
      cf_list.field_type = 'select'
      expect(cf_list.input_element).to have_selector('option[selected]', text: 'Please select')
      cf_list.set_value('bar')

      cf_text.expect_inactive!
      cf_list.expect_inactive!

      wp_table.expect_notification(
        message: 'Successful update. Click here to open this work package in fullscreen view.'
      )

      work_package.reload
      expect(work_package.custom_field_1).to eq('bar')
      expect(work_package.custom_field_2).to eq('my custom text')

      # Saveguard to let the background update complete
      wp_table.visit!
      wp_table.expect_work_package_listed(work_package)
    end
  end
end
