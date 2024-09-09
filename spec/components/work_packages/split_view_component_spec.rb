# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackages::SplitViewComponent, type: :component do
  include OpenProject::StaticRouting::UrlHelpers

  let(:project)      { create(:project) }
  let(:work_package) { create(:work_package, project:) }

  subject do
    with_controller_class(NotificationsController) do
      with_request_url("/notifications/details/:work_package_id") do
        render_inline(described_class.new(id: work_package.id, base_route: notifications_path))
      end
    end
  end

  before do
    allow(WorkPackage).to receive(:visible).and_return(WorkPackage.where(id: work_package.id))
  end

  it "renders successfully" do
    subject

    expect(page).to have_text("Overview")
    expect(page).to have_test_selector("wp-details-tab-component--tabs")
    expect(page).to have_test_selector("wp-details-tab-component--close")
    expect(page).to have_test_selector("wp-details-tab-component--full-screen")
  end
end
