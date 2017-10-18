require "spec_helper"
require "support/pages/abstract_work_package"

describe "multi select custom values", js: true do
  let(:type) { FactoryGirl.create :type }
  let(:project) { FactoryGirl.create :project, types: [type] }

  let(:custom_field) do
    FactoryGirl.create(
      :list_wp_custom_field,
      name: "Ingredients",
      multi_value: true,
      types: [type],
      projects: [project],
      possible_values: ["ham", "onions", "pineapple", "mushrooms"]
    )
  end

  def custom_value_for(str)
    custom_field.custom_options.find { |co| co.value == str }.try(:id)
  end

  let(:wp_page) { Pages::FullWorkPackage.new work_package }
  let(:wp_table) { Pages::WorkPackagesTable.new project }
  let(:hierarchy) { ::Components::WorkPackages::Hierarchies.new }
  let(:columns) { ::Components::WorkPackages::Columns.new }
  let(:user) { FactoryGirl.create :admin }

  context "with existing custom values" do
    let(:work_package) do
      wp = FactoryGirl.build :work_package, project: project, type: type

      wp.custom_field_values = {
        custom_field.id => ["ham", "pineapple", "onions"].map { |s| custom_value_for(s) }
      }

      wp.save
      wp
    end

    let(:work_package2) do
      wp = FactoryGirl.build :work_package, project: project, type: type

      wp.custom_field_values = {
        custom_field.id => ["ham"].map { |s| custom_value_for(s) }
      }

      wp.save
      wp
    end

    describe 'in single view' do
      let(:edit_field) do
        field = wp_page.edit_field "customField#{custom_field.id}"
        field.field_type = 'select'
        field
      end

      before do
        login_as(user)

        wp_page.visit!
        wp_page.ensure_page_loaded
      end

      it "should be shown and allowed to be updated" do
        expect(page).to have_text custom_field.name
        expect(page).to have_text "ham"
        expect(page).to have_text "pineapple"
        expect(page).to have_text "onions"

        edit_field.activate!
        sel = edit_field.input_element

        sel.unselect "pineapple"
        sel.select "mushrooms"

        edit_field.submit_by_dashboard

        expect(page).to have_selector('.custom-option.-multiple-lines', count: 3)
        expect(page).to have_text "Successful update"

        expect(page).to have_text custom_field.name
        expect(page).to have_text "ham"
        expect(page).not_to have_text "pineapple"
        expect(page).to have_text "onions"
        expect(page).to have_text "mushrooms"
      end
    end

    describe 'in the WP table' do
      let(:table_edit_field) do
        field = wp_table.edit_field work_package, "customField#{custom_field.id}"
        field.field_type = 'select'
        field
      end

      before do
        work_package
        work_package2

        login_as(user)

        wp_table.visit!
        wp_table.expect_work_package_listed(work_package)
        wp_table.expect_work_package_listed(work_package2)

        columns.add custom_field.name
      end

      it 'should be usable in the table and split view context' do
        # Disable hierarchies
        hierarchy.disable_hierarchy
        hierarchy.expect_no_hierarchies

        # Should show truncated values
        expect(page).to have_text "ham, pineapple, ... 3"
        expect(page).not_to have_text "onions"

        # Group by the CF
        wp_table.click_setting_item 'Group by ...'
        select 'Ingredients', from: 'selected_columns_new'
        click_button 'Apply'

        loading_indicator_saveguard

        # Expect changed groups
        expect(page).to have_selector('.group--value .count', count: 2)
        expect(page).to have_selector('.group--value', text: 'ham, onions, pineapple (1)')
        expect(page).to have_selector('.group--value', text: 'ham (1)')

        table_edit_field.activate!
        sel = table_edit_field.input_element

        sel.unselect "pineapple"
        sel.unselect "onions"

        table_edit_field.submit_by_dashboard

        # Expect changed groups
        expect(page).to have_selector('.group--value .count', count: 1)
        expect(page).to have_selector('.group--value', text: 'ham (2)')

        # Open split view
        split_view = wp_table.open_split_view work_package
        field = WorkPackageMultiSelectField.new(split_view.container, "customField#{custom_field.id}")

        field.activate!
        sel = field.input_element
        expect(field).not_to be_multiselect

        field.toggle_multiselect
        expect(field).to be_multiselect
        sel.unselect "ham"
        field.submit_by_dashboard

        # Expect none selected in split and table
        field.expect_state_text '-'
        table_edit_field.expect_state_text '-'

        # Activate again
        field.activate!
        field.toggle_multiselect
        expect(field).to be_multiselect
        sel.select "ham"
        sel.select "onions"

        field.submit_by_dashboard

        expect(field.display_element).to have_text('ham')
        expect(field.display_element).to have_text('onions')
        table_edit_field.expect_state_text 'ham, onions'

        field.activate!
        # Is now multiselect from the start, since multiple values enabled
        expect(field).to be_multiselect
        sel.select "pineapple"
        sel.select "mushrooms"

        field.submit_by_dashboard
        expect(field.display_element).to have_text('ham')
        expect(field.display_element).to have_text('onions')
        expect(field.display_element).to have_text('pineapple')
        expect(field.display_element).to have_text('mushrooms')

        table_edit_field.expect_state_text ', ... 4'
      end
    end
  end
end
