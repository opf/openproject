require 'spec_helper'

describe 'Switching types in work package table', js: true do
  let(:user) { FactoryBot.create :admin }

  describe 'switching to required CF' do
    let(:cf_req_text) do
      FactoryBot.create(
        :work_package_custom_field,
        field_format: 'string',
        name: 'Required CF',
        is_required: true,
        is_for_all: false
      )
    end
    let(:cf_text) do
      FactoryBot.create(
        :work_package_custom_field,
        field_format: 'string',
        is_required: false,
        is_for_all: false
      )
    end

    let(:type_task) { FactoryBot.create(:type_task, custom_fields: [cf_text]) }
    let(:type_bug) { FactoryBot.create(:type_bug, custom_fields: [cf_req_text]) }

    let(:project) do
      FactoryBot.create(
        :project,
        types: [type_task, type_bug],
        work_package_custom_fields: [cf_text, cf_req_text]
      )
    end
    let(:work_package) do
      FactoryBot.create(:work_package,
                        subject: 'Foobar',
                        type: type_task,
                        project: project)
    end
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }

    let(:query) do
      query = FactoryBot.build(:query, user: user, project: project)
      query.column_names = ['id', 'subject', 'type', "cf_#{cf_text.id}"]

      query.save!
      query
    end

    let(:type_field) { wp_table.edit_field(work_package, :type) }
    let(:text_field) { wp_table.edit_field(work_package, :"customField#{cf_text.id}") }
    let(:req_text_field) { wp_table.edit_field(work_package, :"customField#{cf_req_text.id}") }

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
        type: :error,
        message: "#{cf_req_text.name} can't be blank."
      )
      # safegurards
      wp_table.dismiss_notification!
      wp_table.expect_no_notification(
        type: :error,
        message: "#{cf_req_text.name} can't be blank."
      )

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

      expect { text_field.display_element }.to raise_error(Capybara::ElementNotFound)

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

      expect(page).to have_no_selector "#{req_text_field.selector} #{req_text_field.display_selector}"
      expect { req_text_field.display_element }.to raise_error(Capybara::ElementNotFound)
    end

    it 'can switch back from an open required CF (Regression test #28099)' do
      # Switch type
      type_field.activate!
      type_field.set_value type_bug.name

      wp_table.expect_notification(
        type: :error,
        message: "#{cf_req_text.name} can't be blank."
      )
      # safegurards
      wp_table.dismiss_notification!
      wp_table.expect_no_notification(
        type: :error,
        message: "#{cf_req_text.name} can't be blank."
      )

      # Required CF requires activation
      req_text_field.expect_active!

      # Now switch back to a type without the required CF
      type_field.activate!
      type_field.openSelectField
      type_field.set_value type_task.name

      wp_table.expect_notification(
        message: 'Successful update. Click here to open this work package in fullscreen view.'
      )
      # safegurards
      wp_table.dismiss_notification!
      wp_table.expect_no_notification(
        message: 'Successful update. Click here to open this work package in fullscreen view.'
      )
    end

    context 'switching to single view' do
      let(:wp_split) { wp_table.open_split_view(work_package) }
      let(:type_field) { wp_split.edit_field(:type) }
      let(:text_field) { wp_split.edit_field(:"customField#{cf_text.id}") }
      let(:req_text_field) { wp_split.edit_field(:"customField#{cf_req_text.id}") }

      it 'allows editing and cancelling the new required fields' do
        wp_split

        # Switch type
        type_field.activate!
        type_field.set_value type_bug.name

        wp_table.expect_notification(
          type: :error,
          message: "#{cf_req_text.name} can't be blank."
        )
        # safegurards
        wp_table.dismiss_notification!
        wp_table.expect_no_notification(
          type: :error,
          message: "#{cf_req_text.name} can't be blank."
        )

        # Required CF requires activation
        req_text_field.expect_active!

        # Cancel edition now
        req_text_field.cancel_by_escape
        req_text_field.expect_state_text '-'

        # Set the value now
        req_text_field.update 'foobar'

        wp_table.expect_notification(
          message: 'Successful update. Click here to open this work package in fullscreen view.'
        )
        # safegurards
        wp_table.dismiss_notification!
        wp_table.expect_no_notification(
          message: 'Successful update. Click here to open this work package in fullscreen view.'
        )

        req_text_field.expect_state_text 'foobar'
      end
    end
  end

  describe 'switching to required bool CF with default value' do
    let(:cf_req_bool) do
      FactoryBot.create(
        :work_package_custom_field,
        field_format: 'bool',
        is_required: true,
        default_value: false
      )
    end

    let(:type_task) { FactoryBot.create(:type_task) }
    let(:type_bug) { FactoryBot.create(:type_bug, custom_fields: [cf_req_bool]) }

    let(:project) do
      FactoryBot.create(
        :project,
        types: [type_task, type_bug],
        work_package_custom_fields: [cf_req_bool]
      )
    end
    let(:work_package) do
      FactoryBot.create(:work_package,
                        subject: 'Foobar',
                        type: type_task,
                        project: project)
    end
    let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
    let(:type_field) { wp_page.edit_field :type }

    before do
      login_as user
      wp_page.visit!
      wp_page.ensure_page_loaded
    end

    it 'can switch to the bug type without errors' do
      type_field.expect_state_text type_task.name.upcase
      type_field.update type_bug.name

      # safegurards
      wp_page.expect_notification message: 'Successful update.'
      wp_page.dismiss_notification!
      wp_page.expect_no_notification message: 'Successful update.'

      type_field.expect_state_text type_bug.name.upcase

      work_package.reload
      expect(work_package.type_id).to eq(type_bug.id)
      expect(work_package.send("custom_field_#{cf_req_bool.id}")).to eq(false)
    end
  end

  describe 'switching to list CF' do
    let!(:wp_page) { Pages::FullWorkPackageCreate.new }
    let!(:type_with_cf) { FactoryBot.create(:type_task, custom_fields: [custom_field]) }
    let!(:type) { FactoryBot.create(:type_bug) }
    let(:permissions) { %i(view_work_packages add_work_packages) }
    let(:role) { FactoryBot.create :role, permissions: permissions }
    let(:user) do
      FactoryBot.create :user,
                        member_in_project: project,
                        member_through_role: role
    end

    let(:custom_field) do
      FactoryBot.create(
        :list_wp_custom_field,
        name: "Ingredients",
        multi_value: true,
        possible_values: ["ham", "onions", "pineapple", "mushrooms"]
      )
    end

    let!(:project) do
      FactoryBot.create(
        :project,
        types: [type, type_with_cf],
        work_package_custom_fields: [custom_field]
      )
    end
    let!(:status) { FactoryBot.create(:default_status) }
    let!(:workflow) do
      FactoryBot.create :workflow,
                        type_id: type.id,
                        old_status: status,
                        new_status: FactoryBot.create(:status),
                        role: role
    end

    let!(:priority) { FactoryBot.create :priority, is_default: true }

    let(:cf_edit_field) do
      field = wp_page.edit_field "customField#{custom_field.id}"
      field.field_type = 'create-autocompleter'
      field
    end

    before do
      workflow
      login_as(user)

      visit new_project_work_packages_path(project.identifier, type: type.id)
      expect_angular_frontend_initialized
    end

    it 'can switch to the type with CF list' do
      # Set subject
      subject = wp_page.edit_field :subject
      subject.set_value 'My subject'

      # Switch type
      type_field = wp_page.edit_field :type
      type_field.activate!
      type_field.set_value type_with_cf.name

      # Scroll to element so it is fully visible
      scroll_to_element(cf_edit_field.field_container)

      cf_edit_field.openSelectField
      cf_edit_field.set_value "pineapple"
      cf_edit_field.set_value "mushrooms"

      wp_page.save!

      wp_page.expect_notification(
        message: 'Successful creation.'
      )

      new_wp = WorkPackage.last
      expect(new_wp.subject).to eq('My subject')
      expect(new_wp.type_id).to eq(type_with_cf.id)
      expect(new_wp.custom_value_for(custom_field.id).map(&:typed_value)).to match_array(%w(pineapple mushrooms))
    end
  end
end
