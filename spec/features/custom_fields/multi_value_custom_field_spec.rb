require "spec_helper"
require "support/pages/work_packages/abstract_work_package"

describe "multi select custom values", clear_cache: true, js: true do
  let(:type) { FactoryBot.create :type }
  let(:project) { FactoryBot.create :project, types: [type] }
  let(:multi_value) { true }

  let(:custom_field) do
    FactoryBot.create(
      :list_wp_custom_field,
      name: "Ingredients",
      multi_value: multi_value,
      types: [type],
      projects: [project],
      possible_values: ["ham", "onions", "pineapple", "mushrooms"]
    )
  end

  def custom_value_for(str)
    custom_field.custom_options.find { |co| co.value == str }.try(:id)
  end

  def table_edit_field(work_package)
    field = wp_table.edit_field work_package, "customField#{custom_field.id}"
    field.field_type = 'create-autocompleter'
    field
  end

  let(:wp_page) { Pages::FullWorkPackage.new work_package }
  let(:wp_table) { Pages::WorkPackagesTable.new project }
  let(:hierarchy) { ::Components::WorkPackages::Hierarchies.new }
  let(:columns) { ::Components::WorkPackages::Columns.new }
  let(:group_by) { ::Components::WorkPackages::GroupBy.new }
  let(:sort_by) { ::Components::WorkPackages::SortBy.new }

  let(:user) { FactoryBot.create :admin }
  let(:cf_frontend) { "customField#{custom_field.id}"}

  context "with existing custom values" do
    let(:work_package_options) { %w[ham pineapple onions] }
    let(:work_package) do
      wp = FactoryBot.build :work_package, project: project, type: type, subject: 'First'

      wp.custom_field_values = {
        custom_field.id => work_package_options.map { |s| custom_value_for(s) }
      }

      wp.save
      wp
    end

    let(:work_package2_options) { %w[ham] }
    let(:work_package2) do
      wp = FactoryBot.build :work_package, project: project, type: type, subject: 'Second'

      wp.custom_field_values = {
        custom_field.id => work_package2_options.map { |s| custom_value_for(s) }
      }

      wp.save
      wp
    end

    describe 'in single view' do
      let(:edit_field) do
        field = wp_page.edit_field "customField#{custom_field.id}"
        field.field_type = 'create-autocompleter'
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

        edit_field.unset_value "pineapple", true
        edit_field.set_value "mushrooms"

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
      let(:wp1_field) { table_edit_field(work_package) }

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
        expect(page).to have_text "ham, pineapple, ...\n3"
        expect(page).not_to have_text "onions"

        # Group by the CF
        group_by.enable_via_menu 'Ingredients'
        loading_indicator_saveguard

        # Expect changed groups
        expect(page).to have_selector('.group--value .count', count: 2)
        expect(page).to have_selector('.group--value', text: 'ham, onions, pineapple (1)')
        expect(page).to have_selector('.group--value', text: 'ham (1)')

        wp1_field.activate!

        wp1_field.unset_value "pineapple", true
        wp1_field.unset_value "onions", true

        wp1_field.submit_by_dashboard

        # Expect changed groups
        expect(page).to have_selector('.group--value .count', count: 1)
        expect(page).to have_selector('.group--value', text: 'ham (2)')

        # Open split view
        split_view = wp_table.open_split_view work_package
        field = SelectField.new(split_view.container, "customField#{custom_field.id}")

        field.activate!
        field.unset_value "ham", true
        field.submit_by_dashboard

        # Expect none selected in split and table
        field.expect_state_text '-'
        wp1_field.expect_state_text '-'

        # Activate again
        field.activate!

        field.set_value "ham"
        field.set_value "onions"

        field.submit_by_dashboard

        expect(field.display_element).to have_text('ham')
        expect(field.display_element).to have_text('onions')
        wp1_field.expect_state_text 'ham, onions'

        field.activate!
        field.set_value "pineapple"
        field.set_value "mushrooms"

        field.submit_by_dashboard
        expect(field.display_element).to have_text('ham')
        expect(field.display_element).to have_text('onions')
        expect(field.display_element).to have_text('pineapple')
        expect(field.display_element).to have_text('mushrooms')

        wp1_field.expect_state_text ", ...\n4"
      end
    end

    describe 'sorting in the table' do
      let(:wp1_field) { table_edit_field(work_package) }
      let(:wp2_field) { table_edit_field(work_package2) }
      let!(:query) do
        query = FactoryBot.build(:query, user: user, project: project)
        query.column_names = ['id', 'type', 'subject', "cf_#{custom_field.id}"]
        query.filters.clear
        query.timeline_visible = false
        query.sort_criteria = [["cf_#{custom_field.id}", 'asc']]

        query.save!
        query
      end

      before do
        work_package
        work_package2

        login_as(user)
      end

      describe 'sorting by the multi select field' do
        let(:multi_value) { true }

        it 'sorts as expected asc and desc' do
          wp_table.visit_query query
          wp_table.expect_work_package_listed(work_package)
          wp_table.expect_work_package_listed(work_package2)

          expect(wp1_field.display_element).to have_text('ham')
          expect(wp1_field.display_element).to have_text('pineapple')
          expect(wp2_field.display_element).to have_text('ham')

          wp_table.expect_work_package_order work_package2, work_package

          # Reverse sort
          sort_by.sort_via_header cf_frontend, descending: true, selector: cf_frontend

          wp_table.expect_work_package_listed(work_package)
          wp_table.expect_work_package_listed(work_package2)
          wp_table.expect_work_package_order work_package, work_package2
        end
      end

      describe 'sorting by the single select field' do
        let(:multi_value) { false }
        let(:work_package2_options) { %w[onions] } # position 2
        let(:work_package_options) { %w[mushrooms] } # position 4

        it 'sorts as expected asc and desc' do
          wp_table.visit_query query
          wp_table.expect_work_package_listed(work_package)
          wp_table.expect_work_package_listed(work_package2)

          expect(wp2_field.display_element).to have_text('onions')
          expect(wp1_field.display_element).to have_text('mushrooms')

          wp_table.expect_work_package_order work_package2, work_package

          # Reverse sort
          sort_by.sort_via_header cf_frontend, descending: true, selector: cf_frontend

          wp_table.expect_work_package_listed(work_package)
          wp_table.expect_work_package_listed(work_package2)
          wp_table.expect_work_package_order work_package, work_package2
        end
      end
    end
  end
end
