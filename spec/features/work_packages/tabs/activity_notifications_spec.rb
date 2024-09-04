require "spec_helper"

require "features/work_packages/work_packages_page"
require "support/edit_fields/edit_field"

RSpec.describe "Activity tab notifications", :js, :selenium do
  shared_let(:project) { create(:project_with_types, public: true) }
  shared_let(:work_package) do
    create(:work_package,
           project:,
           journals: {
             6.days.ago => {},
             5.days.ago => { notes: "First comment on this wp." },
             4.days.ago => { notes: "Second comment on this wp." },
             3.days.ago => { notes: "Third comment on this wp." }
           })
  end
  shared_let(:admin) { create(:admin) }

  shared_examples_for "when there are notifications for the work package" do
    shared_let(:notification) do
      create(:notification,
             recipient: admin,
             resource: work_package,
             journal: work_package.journals.last)
    end
    it "shows a notification bubble with the right number" do
      expect(page).to have_test_selector("tab-counter-Activity", text: "1")
    end

    it "shows a notification icon next to activities that have an unread notification" do
      expect(page).to have_test_selector("user-activity-bubble", count: 1)
      expect(page).to have_css("[data-qa-activity-number='4'] #{test_selector('user-activity-bubble')}")
    end

    it "shows a button to mark the notifications as read" do
      expect(page).to have_test_selector("mark-notification-read-button")

      # A click marks the notification as read ...
      page.find_test_selector("mark-notification-read-button").click

      # ... and updates the view accordingly
      expect(page).not_to have_test_selector("mark-notification-read-button")
      expect(page).not_to have_test_selector("tab-counter-Activity")
      expect(page).not_to have_test_selector("user-activity-bubble")
    end
  end

  shared_examples_for "when there are no notifications for the work package" do
    it "shows no notification bubble" do
      expect(page).not_to have_test_selector("tab-counter-Activity")
    end

    it "does not show any notification icons next to activities" do
      expect(page).not_to have_test_selector("user-activity-bubble")
    end

    it "shows no button to mark the notifications as read" do
      expect(page).not_to have_test_selector("mark-notification-read-button")
    end
  end

  context "when on full view" do
    shared_let(:full_view) { Pages::FullWorkPackage.new(work_package, project) }

    before do
      login_as(admin)
      full_view.visit_tab! "activity"
    end

    it_behaves_like "when there are notifications for the work package"

    it_behaves_like "when there are no notifications for the work package"
  end

  context "when on split view" do
    shared_let(:split_view) { Pages::SplitWorkPackage.new(work_package, project) }

    before do
      login_as(admin)
      split_view.visit_tab! "activity"
    end

    it_behaves_like "when there are notifications for the work package"

    it_behaves_like "when there are no notifications for the work package"
  end

  context "when visiting as an anonymous user", with_settings: { login_required?: false } do
    let(:full_view) { Pages::FullWorkPackage.new(work_package, project) }
    let!(:anonymous_role) do
      create(:anonymous_role, permissions: [:view_work_packages])
    end

    it "does not show an error" do
      full_view.visit_tab! "activity"
      full_view.ensure_page_loaded

      full_view.expect_no_toaster type: :error, message: "Http failure response for"
      full_view.expect_no_toaster
    end
  end
end
