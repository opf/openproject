require "spec_helper"

RSpec.describe "Notification center navigation", :js, :with_cuprite do
  shared_association_default(:project) { create(:project) }

  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:second_work_package) { create(:work_package, project:) }
  shared_let(:recipient) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages] })
  end
  shared_let(:notification) do
    create(:notification,
           recipient:,
           resource: work_package,
           journal: work_package.journals.last)
  end

  shared_let(:second_notification) do
    create(:notification,
           recipient:,
           resource: second_work_package,
           journal: second_work_package.journals.last)
  end

  let(:center) { Pages::Notifications::Center.new }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }
  let(:split_screen) { Pages::PrimerizedSplitWorkPackage.new work_package }

  current_user { recipient }

  describe "the path updates accordingly" do
    it "when navigating between the tabs" do
      visit home_path
      center.open
      center.expect_bell_count 2
      expect(page).to have_current_path "/notifications"

      # Details view of WP opens with activity tab
      center.click_item notification
      split_screen.expect_open
      expect(page).to have_current_path "/notifications/details/#{work_package.id}/activity"

      # Switch to the relations tab
      split_screen.switch_to_tab tab: "Relations"
      expect(page).to have_current_path "/notifications/details/#{work_package.id}/relations"

      # Navigate to full view and back
      wp_full = split_screen.switch_to_fullscreen
      expect(page).to have_current_path "/projects/#{project.identifier}/work_packages/#{work_package.id}/relations"

      page.execute_script("window.history.back()")
      expect(page).to have_current_path "/notifications/details/#{work_package.id}/relations"

      # Close the split screen
      split_screen.close
      expect(page).to have_current_path "/notifications"
    end
  end

  context "when filtering for notifications" do
    it "keeps the state when opening and closing notifications (Regression #57067)" do
      visit notifications_path

      within_test_selector("op-submenu") do
        click_link_or_button "Mentioned"
      end
      expect(page).to have_current_path "/notifications?filter=reason&name=mentioned"

      # Details view of WP opens with activity tab
      center.click_item notification
      split_screen.expect_open
      expect(page).to have_current_path "/notifications/details/#{work_package.id}/activity?filter=reason&name=mentioned"

      # Switch to the relations tab
      split_screen.switch_to_tab tab: "Relations"
      expect(page).to have_current_path "/notifications/details/#{work_package.id}/relations?filter=reason&name=mentioned"

      # Close the split screen
      split_screen.close
      expect(page).to have_current_path "/notifications?filter=reason&name=mentioned"
    end
  end

  it "opening a notification that does not exist returns to the center" do
    visit "/notifications/details/0"

    expect(page).to have_current_path "/notifications/details/0"
    expect(page).to have_text "The work package was not found."
  end

  it "deep linking to a notification details highlights it" do
    visit "/notifications/details/#{work_package.id}"

    expect(page).to have_current_path "/notifications/details/#{work_package.id}"

    split_screen.expect_open

    center.expect_item_selected notification
  end

  context "if the work package has a parent" do
    before do
      work_package.update! parent: second_work_package
    end

    it "can link to that parent from notifications (Regression #42984)" do
      visit "/notifications/details/#{work_package.id}"

      expect(page).to have_current_path "/notifications/details/#{work_package.id}"

      split_screen.expect_open

      expect(page).to have_test_selector("op-wp-breadcrumb-parent", text: second_work_package.subject)

      page.find_test_selector("op-wp-breadcrumb-parent").click

      expect(page).to have_current_path /\/work_packages\/#{second_work_package.id}/

      # Works with another tab as well
      visit "/notifications/details/#{work_package.id}/relations"

      expect(page).to have_current_path "/notifications/details/#{work_package.id}/relations"

      page.find_test_selector("op-wp-breadcrumb-parent").click

      expect(page).to have_current_path /\/work_packages\/#{second_work_package.id}/
    end
  end
end
