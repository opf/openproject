# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "My hourly rates", type: :rails_request do
  shared_let(:project) { create(:project, name: "Apollo") }
  shared_let(:other_project) { create(:project, name: "Gemini") }

  context "when the user may only view their own rate" do
    shared_let(:user) do
      create(:user, member_with_permissions: { project => %i[view_own_hourly_rate] })
    end

    shared_let(:own_rate) { create(:hourly_rate, principal: user, project:, rate: 95) }

    current_user { user }

    it "lists the rate of that project" do
      get my_hourly_rates_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(project.name)
      expect(response.body).to include("95.00")
    end

    it "offers no way to add a rate" do
      get my_hourly_rates_path

      expect(response.body).not_to include(new_projects_hourly_rate_path(project_id: project, principal_id: user.id))
    end

    it "does not list the default rates separately" do
      create(:default_hourly_rate, principal: user, rate: 30)

      get my_hourly_rates_path

      expect(response.body).not_to include("rate-history-default")
    end
  end

  context "when the user may edit their own rate" do
    shared_let(:user) do
      create(:user, member_with_permissions: { project => %i[view_own_hourly_rate edit_own_hourly_rate] })
    end

    current_user { user }

    it "offers adding a rate for that project" do
      get my_hourly_rates_path

      expect(response.body).to include(new_projects_hourly_rate_path(project_id: project, principal_id: user.id))
    end
  end

  # The default rates table is left out here, so the default rate has to reach
  # the user through the projects it applies to.
  context "with a project that has no rate of its own" do
    shared_let(:user) do
      create(:user, member_with_permissions: { project => %i[view_own_hourly_rate] })
    end

    shared_let(:default_rate) { create(:default_hourly_rate, principal: user, rate: 30) }

    current_user { user }

    it "names the default rate as the one in effect there" do
      get my_hourly_rates_path

      expect(response.body).to include(project.name)
      expect(response.body).to include(I18n.t(:label_using_current_default_rate))
      expect(response.body).to include("30.00")
    end
  end

  context "when the user has no rate permission at all" do
    current_user { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "is forbidden" do
      get my_hourly_rates_path

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "with a project the user cannot see rates in" do
    shared_let(:user) do
      create(:user, member_with_permissions: { project => %i[view_own_hourly_rate],
                                               other_project => %i[view_work_packages] })
    end

    shared_let(:hidden_rate) { create(:hourly_rate, principal: user, project: other_project, rate: 123) }

    current_user { user }

    it "leaves that project out" do
      get my_hourly_rates_path

      expect(response.body).not_to include("123.00")
      expect(response.body).not_to include(other_project.name)
    end
  end
end
