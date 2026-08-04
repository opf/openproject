# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Projects::Settings::WorkPackages::Types::Switches",
               :skip_csrf,
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:design) { create(:type, name: "Design", parent: epic) }
  shared_let(:blueprint) { create(:type, name: "Blueprint", parent: epic) }
  shared_let(:project) { create(:project, types: [design]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[edit_project manage_types view_work_packages] })
  end

  subject(:switch!) do
    post project_settings_work_packages_type_switch_path(project, design),
         params: { switch: { target_id: blueprint.id } },
         as: :turbo_stream
  end

  let(:status_when_checked) { :in_queue }
  let(:message_when_checked) { "The project now uses Epic: Blueprint." }

  # The job is never really run. What the branch depends on is only what the
  # status row says by the time the debounce window is checked, so the spec sets
  # that directly instead of racing a worker.
  before do
    login_as user
    stub_const("Projects::Settings::WorkPackages::Types::SwitchesController::DEBOUNCE_SECONDS", 0.1)

    allow(Projects::Types::SwitchVariantJob).to receive(:perform_later) do
      job_id = SecureRandom.uuid

      JobStatus::Status.create!(
        job_id:,
        user:,
        status: status_when_checked,
        message: message_when_checked,
        payload: { "kind" => "type_switch", "project_id" => project.id,
                   "source_id" => design.id, "target_id" => blueprint.id }
      )

      instance_double(Projects::Types::SwitchVariantJob, job_id:)
    end
  end

  context "when the switch settles inside the debounce window" do
    let(:status_when_checked) { :success }

    it "reports the outcome and shows no spinner" do
      switch!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("The project now uses Epic: Blueprint.")
      expect(response.body).not_to include("Switching to variant:")
    end
  end

  context "when the switch outlives the debounce window" do
    it "marks the switching row as running" do
      switch!

      expect(response).to have_http_status(:accepted)
      expect(response.body).to include("Switching to variant:")
    end
  end

  context "when the switch fails inside the debounce window" do
    let(:status_when_checked) { :failure }
    let(:message_when_checked) { "Type is not writable." }

    it "reports the failure rather than staying silent" do
      switch!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Type is not writable.")
      expect(response.body).not_to include("Switching to variant:")
    end
  end
end
