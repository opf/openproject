require "spec_helper"
require "features/page_objects/notification"

RSpec.describe "Notification center date alert and mention",
               :js,
               :with_cuprite,
               with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:project) { create(:project) }
  shared_let(:actor) { create(:user, firstname: "Actor", lastname: "User") }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %w[view_work_packages] })
  end
  shared_let(:work_package) { create(:work_package, project:, due_date: 1.day.ago) }

  shared_let(:notification_mention) do
    create(:notification,
           reason: :mentioned,
           recipient: user,
           resource: work_package,
           actor:)
  end

  shared_let(:notification_date_alert) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: work_package)
  end

  let(:center) { Pages::Notifications::Center.new }

  before do
    login_as user
    visit notifications_center_path
    wait_for_reload
  end

  context "with date alerts ee", with_ee: %i[date_alerts] do
    it "shows only the date alert time, not the mentioned author" do
      center.within_item(notification_date_alert) do
        expect(page).to have_text("Date alert, Mentioned")
        expect(page).to have_no_text("Actor user")
      end
    end
  end
end
