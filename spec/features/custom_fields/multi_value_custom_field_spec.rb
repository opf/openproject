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
  let(:wp_table) { Pages::WorkPackagesTable.new }
  let(:user) { FactoryGirl.create :admin }

  context "with existing custom values" do
    let(:work_package) do
      wp = FactoryGirl.create :work_package, project: project, type: type

      wp.custom_field_values = {
        custom_field.id => ["ham", "pineapple", "onions"].map { |s| custom_value_for(s) }
      }

      wp.save
      wp
    end

    before do
      login_as(user)

      wp_page.visit!
      wp_page.ensure_page_loaded
    end

    include_context 'work package table helpers'

    it "should be shown and allowed to be updated" do
      expect(page).to have_text custom_field.name
      expect(page).to have_text "ham"
      expect(page).to have_text "pineapple"
      expect(page).to have_text "onions"

      page.find("div.custom-option", text: "ham").click

      sel = page.find(:select)

      sel.unselect "pineapple"
      sel.select "mushrooms"

      click_on "Ingredients: Save"

      expect(page).to have_selector('.custom-option.-multiple-lines', count: 3)
      expect(page).to have_text "Successful update"

      expect(page).to have_text custom_field.name
      expect(page).to have_text "ham"
      expect(page).not_to have_text "pineapple"
      expect(page).to have_text "onions"
      expect(page).to have_text "mushrooms"
    end

    it 'should truncate the field in the WP table' do
      wp_table.visit!
      wp_table.expect_work_package_listed(wp_page)
      add_wp_table_column(custom_field.name)

      expect(page).to have_text "ham , pineapple , ... 3"
      expect(page).not_to have_text "onions"
    end
  end
end
