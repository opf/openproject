require "spec_helper"
require "support/pages/work_packages/abstract_work_package"

RSpec.describe "multi select custom values", :js, :with_cuprite do
  let(:type) { create(:type) }
  let(:wp_page) { Pages::FullWorkPackage.new work_package }
  let(:wp_table) { Pages::WorkPackagesTable.new project }
  let(:hierarchy) { Components::WorkPackages::Hierarchies.new }
  let(:columns) { Components::WorkPackages::Columns.new }
  let(:group_by) { Components::WorkPackages::GroupBy.new }
  let(:sort_by) { Components::WorkPackages::SortBy.new }
  let(:user) { create(:admin) }
  let(:cf_frontend) { custom_field.attribute_name(:camel_case) }
  let(:project) { create(:project, types: [type]) }
  let(:multi_value) { true }

  let(:custom_field) do
    create(
      :list_wp_custom_field,
      name: "Ingredients",
      multi_value:,
      types: [type],
      projects: [project],
      possible_values: ["ham", "onions", "pineapple", "mushrooms"]
    )
  end

  def custom_value_for(str)
    custom_field.custom_options.find { |co| co.value == str }.try(:id)
  end

  def table_edit_field(work_package)
    field = wp_table.edit_field work_package, custom_field.attribute_name(:camel_case)
    field.field_type = "create-autocompleter"
    field
  end

  context "with existing custom values" do
    let(:work_package_options) { %w[ham pineapple onions] }
    let(:work_package) do
      wp = build(:work_package, project:, type:, subject: "First")

      wp.custom_field_values = {
        custom_field.id => work_package_options.map { |s| custom_value_for(s) }
      }

      wp.save
      wp
    end

    let(:work_package2_options) { %w[ham] }
    let(:work_package2) do
      wp = build(:work_package, project:, type:, subject: "Second")

      wp.custom_field_values = {
        custom_field.id => work_package2_options.map { |s| custom_value_for(s) }
      }

      wp.save
      wp
    end

    describe "in single view" do
      let(:edit_field) do
        field = wp_page.edit_field custom_field.attribute_name(:camel_case)
        field.field_type = "create-autocompleter"
        field
      end

      before do
        login_as(user)

        wp_page.visit!
        wp_page.ensure_page_loaded
      end

      it "is shown and allowed to be updated" do
        expect(page).to have_text custom_field.name
        expect(page).to have_text "ham"
        expect(page).to have_text "pineapple"
        expect(page).to have_text "onions"

        edit_field.activate!

        edit_field.unset_value "pineapple", multi: true
        edit_field.set_value "mushrooms"

        edit_field.submit_by_dashboard

        expect(page).to have_css(".custom-option.-multiple-lines", count: 3)
        expect(page).to have_text "Successful update"

        expect(page).to have_text custom_field.name
        expect(page).to have_text "ham"
        expect(page).to have_no_text "pineapple"
        expect(page).to have_text "onions"
        expect(page).to have_text "mushrooms"
      end
    end

    describe "in the WP table" do
      # Memoizing wp1_field via a let does not work. After a couple of updates to the custom field,
      # an expectation like
      #   wp1_field.expect_state_text "ham, onions, pineapple"
      # fails with unhandled inspector error: {"code":-32000,"message":"No node with given id found"}
      # as of chrome 113. The context memoized in the wp1_field seems to become an invalid reference.
      def wp1_field
        table_edit_field(work_package)
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

      it "is usable in the table and split view context" do
        # Disable hierarchies
        hierarchy.disable_hierarchy
        hierarchy.expect_no_hierarchies

        # Should show truncated values
        expect(page).to have_text "ham, pineapple, ...3"
        expect(page).to have_no_text "onions"

        # Group by the CF
        group_by.enable_via_menu "Ingredients"
        loading_indicator_saveguard

        # Expect changed groups
        expect(page).to have_css(".group--value .count", count: 2)
        expect(page).to have_css(".group--value", text: "ham, onions, pineapple (1)")
        expect(page).to have_css(".group--value", text: "ham (1)")

        wp1_field.activate!

        wp1_field.unset_value "pineapple", multi: true
        wp1_field.unset_value "onions", multi: true

        wp1_field.submit_by_dashboard

        wp_page.expect_and_dismiss_toaster message: "Successful update"

        # Expect changed groups
        expect(page).to have_css(".group--value .count", count: 1)
        expect(page).to have_css(".group--value", text: "ham (2)")

        # Open split view
        split_view = wp_table.open_split_view work_package
        field = SelectField.new(split_view.container, custom_field.attribute_name(:camel_case))

        field.activate!
        field.unset_value "ham", multi: true
        field.submit_by_dashboard

        wp_page.expect_and_dismiss_toaster message: "Successful update"

        # Expect none selected in split and table
        field.expect_state_text "-"
        wp1_field.expect_state_text "-"

        # Expect changed groups
        expect(page).to have_css(".group--value .count", count: 2)
        expect(page).to have_css(".group--value", text: "- (1)")
        expect(page).to have_css(".group--value", text: "ham (1)")

        # Activate again
        field.activate!

        field.set_value "ham"
        field.set_value "onions"

        field.submit_by_dashboard

        # Expect changed groups
        expect(page).to have_css(".group--value .count", count: 2)
        expect(page).to have_css(".group--value", text: "ham, onions (1)")
        expect(page).to have_css(".group--value", text: "ham (1)")

        expect(field.display_element).to have_text("ham")
        expect(field.display_element).to have_text("onions")
        wp1_field.expect_state_text "ham, onions"

        field.activate!
        field.set_value "pineapple"
        field.set_value "mushrooms"

        field.submit_by_dashboard
        expect(field.display_element).to have_text("ham")
        expect(field.display_element).to have_text("onions")
        expect(field.display_element).to have_text("pineapple")
        expect(field.display_element).to have_text("mushrooms")

        # Expect changed groups
        expect(page).to have_css(".group--value .count", count: 2)
        expect(page).to have_css(".group--value", text: "ham, mushrooms, onions, pineapple (1)")
        expect(page).to have_css(".group--value", text: "ham (1)")

        wp1_field.expect_state_text ", ...4"
      end
    end

    describe "sorting in the table" do
      let(:wp1_field) { table_edit_field(work_package) }
      let(:wp2_field) { table_edit_field(work_package2) }
      let!(:query) do
        query = build(:query, user:, project:)
        query.column_names = ["id", "type", "subject", custom_field.column_name]
        query.filters.clear
        query.timeline_visible = false
        query.sort_criteria = [[custom_field.column_name, "asc"]]

        query.save!
        query
      end

      before do
        work_package
        work_package2

        login_as(user)
      end

      describe "sorting by the multi select field" do
        let(:multi_value) { true }

        it "sorts as expected asc and desc" do
          wp_table.visit_query query
          wp_table.expect_work_package_listed(work_package)
          wp_table.expect_work_package_listed(work_package2)

          expect(wp1_field.display_element).to have_text("ham")
          expect(wp1_field.display_element).to have_text("pineapple")
          expect(wp2_field.display_element).to have_text("ham")

          wp_table.expect_work_package_order work_package2, work_package

          # Reverse sort
          sort_by.sort_via_header cf_frontend, descending: true, selector: cf_frontend

          wp_table.expect_work_package_listed(work_package)
          wp_table.expect_work_package_listed(work_package2)
          wp_table.expect_work_package_order work_package, work_package2
        end
      end

      describe "sorting by the single select field" do
        let(:multi_value) { false }
        let(:work_package2_options) { %w[onions] } # position 2
        let(:work_package_options) { %w[mushrooms] } # position 4

        it "sorts as expected asc and desc" do
          wp_table.visit_query query
          wp_table.expect_work_package_listed(work_package)
          wp_table.expect_work_package_listed(work_package2)

          expect(wp2_field.display_element).to have_text("onions")
          expect(wp1_field.display_element).to have_text("mushrooms")

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
