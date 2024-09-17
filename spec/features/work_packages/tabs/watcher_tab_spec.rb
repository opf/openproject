require "spec_helper"

RSpec.describe "Watcher tab", :js, :selenium do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:tabs) { Components::WorkPackages::Tabs.new(work_package) }
  let(:role) { create(:project_role, permissions:) }
  let(:user) { create(:user, member_with_roles: { project => role }) }
  let(:permissions) do
    %i(view_work_packages
       view_work_package_watchers
       delete_work_package_watchers
       add_work_package_watchers)
  end

  let(:watch_button) { find_by_id "watch-button" }
  let(:watchers_tab) { find(".op-tab-row--link_selected", text: "WATCHERS") }

  def expect_button_is_watching
    title = I18n.t("js.label_unwatch_work_package")
    expect(page).to have_css("#unwatch-button[title='#{title}']", wait: 10)
    expect(page).to have_css("#unwatch-button .button--icon.icon-watched", wait: 10)
  end

  def expect_button_is_not_watching
    title = I18n.t("js.label_watch_work_package")
    expect(page).to have_css("#watch-button[title='#{title}']")
    expect(page).to have_css("#watch-button .button--icon.icon-unwatched")
  end

  shared_examples "watch and unwatch with button" do
    it "watching the WP modifies the watcher list" do
      # Expect WP watch button is in not-watched state
      expect_button_is_not_watching
      expect(page).not_to have_test_selector("op-wp-watcher-name")
      watch_button.click

      # Expect WP watch button causes watcher list to add user
      expect_button_is_watching
      expect(page).to have_test_selector("op-wp-watcher-name", count: 1, text: user.name)

      # Expect WP unwatch button causes watcher list to remove user
      watch_button.click
      expect_button_is_not_watching
      expect(page).not_to have_test_selector("op-wp-watcher-name")
    end
  end

  shared_examples "watchers tab" do
    before do
      login_as(user)
      wp_page.visit_tab! :watchers
      expect_angular_frontend_initialized
      wp_page.expect_tab "Watchers"
    end

    it "modifying the watcher list modifies the watch button" do
      # Add user as watcher
      autocomplete = find(".wp-watcher--autocomplete ng-select")
      select_autocomplete autocomplete,
                          query: user.firstname,
                          select_text: user.name,
                          results_selector: "body"

      # Expect the addition of the user to toggle WP watch button
      expect(page).to have_test_selector("op-wp-watcher-name", count: 1, text: user.name)
      expect_button_is_watching

      # Expect watchers counter to increase
      tabs.expect_counter(watchers_tab, 1)

      # Remove watcher from list
      page.find_test_selector("op-wp-watcher-name", text: user.name).hover
      page.find(".form--selected-value--remover").click

      # Watchers counter should not be displayed
      tabs.expect_no_counter(watchers_tab)

      # Expect the removal of the user to toggle WP watch button
      expect(page).not_to have_test_selector("op-wp-watcher-name")
      expect_button_is_not_watching
    end

    context "with a user with arbitrary characters" do
      let!(:html_user) do
        create(:user,
               :skip_validations,
               firstname: "<em>foo</em>",
               member_with_roles: { project => role })
      end

      it "escapes the user name" do
        autocomplete = find(".wp-watcher--autocomplete ng-select")
        target_dropdown = search_autocomplete autocomplete,
                                              query: "foo",
                                              results_selector: "body"

        expect(target_dropdown).to have_css(".ng-option", text: html_user.firstname)
        expect(target_dropdown).to have_no_css(".ng-option em")
      end
    end

    context "with all permissions" do
      it_behaves_like "watch and unwatch with button"
    end

    context "without watchers permission" do
      let(:permissions) { %i(view_work_packages view_work_package_watchers) }

      it_behaves_like "watch and unwatch with button"
    end
  end

  context "within a split screen" do
    let(:wp_page) { Pages::SplitWorkPackage.new(work_package) }

    it_behaves_like "watchers tab"
  end

  context "within a primerized split screen" do
    let(:wp_page) { Pages::PrimerizedSplitWorkPackage.new(work_package) }
    let(:tabs) { Components::WorkPackages::PrimerizedTabs.new }
    let(:watchers_tab) { "watchers" }

    it_behaves_like "watchers tab"
  end

  context "within a full screen" do
    let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

    it_behaves_like "watchers tab"
  end

  context "when the work package has a watcher" do
    let(:watchers) { create(:watcher, watchable: work_package, user:) }
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }

    before do
      watchers
      login_as(user)
      wp_table.visit!
      wp_table.expect_work_package_listed work_package
    end

    it "shows the number of watchers [#33685]" do
      wp_table.open_full_screen_by_doubleclick(work_package)
      expect(page).to have_test_selector("tab-count", text: "(1)")
    end
  end

  context "with a placeholder user in the project" do
    let!(:placeholder) { create(:placeholder_user, name: "PLACEHOLDER") }
    let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

    before do
      login_as(user)
      wp_page.visit_tab! :watchers
    end

    it "does not show the placeholder user as an option" do
      autocomplete = find(".wp-watcher--autocomplete ng-select")
      target_dropdown = search_autocomplete autocomplete,
                                            query: "",
                                            results_selector: "body"

      expect(target_dropdown).to have_css(".ng-option", text: user.name)
      expect(target_dropdown).to have_no_css(".ng-option", text: placeholder.name)
    end
  end
end
