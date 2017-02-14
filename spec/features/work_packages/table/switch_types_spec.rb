require 'spec_helper'

describe 'Switching types in work package table', js: true do
  let(:user) { FactoryGirl.create :admin }
  let(:cf_req_text) {
    FactoryGirl.create(
      :work_package_custom_field,
      field_format: 'string',
      is_required:  true,
      is_for_all:   false
    )
  }
  let(:cf_text) {
    FactoryGirl.create(
      :work_package_custom_field,
      field_format: 'string',
      is_required:  false,
      is_for_all:   false
    )
  }

  let(:type_task) { FactoryGirl.create(:type_task, custom_fields: [cf_text]) }
  let(:type_bug) { FactoryGirl.create(:type_bug, custom_fields: [cf_req_text]) }

  let(:project) {
    FactoryGirl.create(
      :project,
      types: [type_task, type_bug],
      work_package_custom_fields: [cf_text, cf_req_text]
    )
  }
  let(:work_package) {
    FactoryGirl.create(:work_package,
                       subject: 'Foobar',
                       type:    type_task,
                       project: project)
  }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let(:query) do
    query              = FactoryGirl.build(:query, user: user, project: project)
    query.column_names = ['subject', 'type', "cf_#{cf_text.id}"]

    query.save!
    query
  end

  let(:type_field) { wp_table.edit_field(work_package, :type) }
  let(:text_field) { wp_table.edit_field(work_package, :customField1) }
  let(:req_text_field) { wp_table.edit_field(work_package, :customField2) }

  before do
    login_as(user)
    query
    project
    work_package

    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(work_package)
  end

  it 'switches the types correctly' do
    expect(text_field).to be_editable

    # Set non-required CF
    text_field.activate!
    text_field.set_value 'Foobar'
    text_field.save!

    wp_table.expect_notification(
      message: 'Successful update. Click here to open this work package in fullscreen view.'
    )
    # safegurards
    wp_table.dismiss_notification!
    wp_table.expect_no_notification(
      message: 'Successful update. Click here to open this work package in fullscreen view.'
    )

    # Switch type
    type_field.activate!
    type_field.set_value type_bug.name

    wp_table.expect_notification(
      type:    :error,
      message: "#{cf_req_text.name} can't be blank."
    )
    # safegurards
    wp_table.dismiss_notification!
    wp_table.expect_no_notification(
      type:    :error,
      message: "#{cf_req_text.name} can't be blank."
    )

    # Old text field should disappear
    text_field.expect_state_text ''

    # Required CF requires activation
    req_text_field.activate!
    req_text_field.set_value 'Required'
    req_text_field.save!

    wp_table.expect_notification(
      message: 'Successful update. Click here to open this work package in fullscreen view.'
    )
    # safegurards
    wp_table.dismiss_notification!
    wp_table.expect_no_notification(
      message: 'Successful update. Click here to open this work package in fullscreen view.'
    )

    expect(text_field).not_to be_editable

    type_field.activate!
    type_field.set_value type_task.name

    wp_table.expect_notification(
      message: 'Successful update. Click here to open this work package in fullscreen view.'
    )
    # safegurards
    wp_table.dismiss_notification!
    wp_table.expect_no_notification(
      message: 'Successful update. Click here to open this work package in fullscreen view.'
    )

    req_text_field.expect_state_text ''
  end
end
