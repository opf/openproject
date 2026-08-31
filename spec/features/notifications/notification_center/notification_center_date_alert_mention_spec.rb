# frozen_string_literal: true

require "spec_helper"
require "features/page_objects/notification"

RSpec.describe "Notification center date alert and mention",
               :js,
               with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:project) { create(:project) }
  shared_let(:actor) { create(:user, firstname: "Actor", lastname: "User") }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %w[view_work_packages] })
  end
  let(:reference_time) { Time.zone.local(2025, 1, 8, 12, 0, 0) }
  let(:work_package) { create(:work_package, project:, due_date: 1.day.ago.to_date) }
  let!(:notification_mention) do
    create(:notification,
           reason: :mentioned,
           recipient: user,
           resource: work_package,
           actor:)
  end

  let!(:notification_date_alert) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: work_package)
  end

  let(:center) { Pages::Notifications::Center.new }

  before do
    travel_to(reference_time)
    login_as user
    visit notifications_center_path
    wait_for_reload
  end

  after do
    travel_back
  end

  context "with date alerts ee", with_ee: %i[date_alerts] do
    it "shows only the date alert time, not the mentioned author" do
      center.within_item(notification_date_alert) do
        expect(page).to have_text("##{work_package.id}\n- #{project.name} -\nDate alert, Mentioned")
        expect(page).to have_no_text("Actor User")
        expect(page).to have_text("Overdue for 1 day.")
      end
    end
  end
end
