# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackages::Details::TabComponent, type: :component do
  include OpenProject::StaticRouting::UrlHelpers

  let(:work_package) { create(:work_package, project:) }

  before { work_package } # realize before render so after_create registration runs

  subject do
    with_controller_class(NotificationsController) do
      with_request_url("/notifications/details/:work_package_id") do
        render_inline(described_class.new(work_package:, base_route: notifications_path))
      end
    end
  end

  describe "full-screen link" do
    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      let(:project) { create(:project, identifier: "MYPROJ") }

      it "uses the semantic displayId in the href" do
        subject

        expect(work_package.display_id).to eq("MYPROJ-1")
        full_screen = page.find("[data-test-selector='wp-details-tab-component--full-screen']")
        expect(full_screen[:href]).to include("/work_packages/MYPROJ-1")
        expect(full_screen[:href]).not_to include("/work_packages/#{work_package.id}/")
      end
    end

    context "in classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      let(:project) { create(:project, identifier: "myproj") }

      it "uses the numeric id in the href" do
        subject

        expect(work_package.display_id).to eq(work_package.id)
        full_screen = page.find("[data-test-selector='wp-details-tab-component--full-screen']")
        expect(full_screen[:href]).to include("/work_packages/#{work_package.id}/")
      end
    end
  end
end
