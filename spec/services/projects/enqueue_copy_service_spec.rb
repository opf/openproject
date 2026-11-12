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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Projects::EnqueueCopyService, type: :model do
  shared_let(:user) { create(:admin) }
  shared_let(:source_project) { create(:project) }
  shared_let(:instance) { described_class.new(user:, model: source_project) }
  let(:target_project_params) { { name: "Target", identifier: "target" } }

  describe "#call" do
    let(:copy_service) { instance_double(Projects::CopyService) }
    let(:test_result) { ServiceResult.success(result: build_stubbed(:project)) }
    let(:mock_job) { instance_double(CopyProjectJob, job_id: "123") }

    before do
      allow(Projects::CopyService).to receive(:new).and_return(copy_service)
      allow(copy_service).to receive(:call).and_return(test_result)
      allow(CopyProjectJob).to receive(:perform_later).and_return(mock_job)
      allow(GoodJob::Batch).to receive(:enqueue).and_yield
    end

    context "with skip_custom_field_validation parameter" do
      let(:params) do
        {
          target_project_params:,
          skip_custom_field_validation: true,
          only: [],
          send_notifications: false
        }
      end

      it "passes skip_custom_field_validation to test copy" do
        instance.call(params)

        expect(Projects::CopyService).to have_received(:new).with(
          hash_including(
            user:,
            source: source_project,
            contract_options: { skip_custom_field_validation: true }
          )
        )
      end

      it "passes skip_custom_field_validation to job" do
        instance.call(params)

        expect(CopyProjectJob).to have_received(:perform_later).with(
          hash_including(skip_custom_field_validation: true)
        )
      end
    end

    context "without skip_custom_field_validation parameter" do
      let(:params) do
        {
          target_project_params:,
          only: [],
          send_notifications: false
        }
      end

      it "does not pass skip_custom_field_validation to test copy" do
        instance.call(params)

        expect(Projects::CopyService).to have_received(:new).with(
          hash_including(
            user:,
            source: source_project,
            contract_options: { skip_custom_field_validation: nil }
          )
        )
      end
    end
  end
end
