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

RSpec.describe Backlogs::WorkPackages::UpdateService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:story) { build_stubbed(:work_package) }
  let(:instance) { described_class.new(user:, story:) }

  let(:inner_service) { instance_double(WorkPackages::UpdateService) }
  let(:inner_result) { ServiceResult.success(result: story) }

  before do
    allow(WorkPackages::UpdateService)
      .to receive(:new).with(user:, model: story)
      .and_return(inner_service)
    allow(inner_service).to receive(:call).and_return(inner_result)
  end

  describe "#call" do
    describe "error handling" do
      shared_examples "returns failure without delegating" do |call_args, i18n_key = nil|
        it "returns failure without delegating", :aggregate_failures do
          i18n_key ||= "backlogs.stories.update_service.invalid_target_type"

          result = instance.call(**call_args)

          expect(result).to be_failure
          expect(result.message).to eq(I18n.t(i18n_key))
          expect(inner_service).not_to have_received(:call)
        end
      end

      context "with neither target_id nor direction" do
        it_behaves_like "returns failure without delegating",
                        {},
                        "backlogs.stories.update_service.missing_target"
      end

      context "with both target_id and direction" do
        it_behaves_like "returns failure without delegating",
                        { target_id: "inbox", direction: "highest" },
                        "backlogs.stories.update_service.ambiguous_target"
      end

      context "when target_id contains an invalid type and id" do
        it_behaves_like "returns failure without delegating", { target_id: "unknown:42" }
      end

      context "when target_id contains an invalid type and no id" do
        it_behaves_like "returns failure without delegating", { target_id: "unknown" }
      end

      %w[sprint backlog_bucket].each do |target_type|
        context "when target_id is '#{target_type}' missing the colon and id" do
          it_behaves_like "returns failure without delegating", { target_id: target_type }
        end

        context "when target_id is '#{target_type}:' missing id" do
          it_behaves_like "returns failure without delegating", { target_id: "#{target_type}:" }
        end

        context "when target_id is '#{target_type}:unknown' having an invalid id" do
          it_behaves_like "returns failure without delegating", { target_id: "#{target_type}:unknown" }
        end
      end

      context "when target_id is 'inbox:' having an extra colon" do
        it_behaves_like "returns failure without delegating", { target_id: "inbox:" }
      end

      context "when target_id is 'inbox:1' having a valid id" do
        it_behaves_like "returns failure without delegating", { target_id: "inbox:1" }
      end

      context "when target_id is 'inbox:unknown' having an invalid id" do
        it_behaves_like "returns failure without delegating", { target_id: "inbox:unknown" }
      end

      context "with an invalid direction" do
        it_behaves_like "returns failure without delegating",
                        { direction: "sideways" },
                        "backlogs.stories.update_service.invalid_direction"
      end
    end

    context "with direction" do
      it "delegates with move_to attribute" do
        instance.call(direction: "highest")

        expect(inner_service).to have_received(:call).with(move_to: "highest")
      end
    end

    context "with target_id: sprint" do
      it "delegates with sprint_id and nil backlog_bucket_id" do
        instance.call(target_id: "sprint:42")

        expect(inner_service).to have_received(:call).with(sprint_id: 42, backlog_bucket_id: nil)
      end
    end

    context "with target_id: backlog_bucket" do
      it "delegates with backlog_bucket_id and nil sprint_id" do
        instance.call(target_id: "backlog_bucket:99")

        expect(inner_service).to have_received(:call).with(backlog_bucket_id: 99, sprint_id: nil)
      end
    end

    context "with target_id: inbox" do
      it "delegates with nil sprint_id and nil backlog_bucket_id" do
        instance.call(target_id: "inbox")

        expect(inner_service).to have_received(:call).with(backlog_bucket_id: nil, sprint_id: nil)
      end
    end

    context "when the inner service fails" do
      let(:inner_result) { ServiceResult.failure(message: "Something went wrong") }

      it "returns the failure without calling move_after", :aggregate_failures do
        allow(story).to receive(:move_after)

        result = instance.call(target_id: "inbox")

        expect(result).to be_failure
        expect(story).not_to have_received(:move_after)
      end
    end

    context "with prev_id" do
      it "calls move_after with the prev_id on success" do
        allow(story).to receive(:move_after)

        instance.call(target_id: "inbox", prev_id: "5")

        expect(story).to have_received(:move_after).with(prev_id: "5")
      end
    end

    context "with position" do
      it "calls move_after with the position on success" do
        allow(story).to receive(:move_after)

        instance.call(target_id: "inbox", position: "3")

        expect(story).to have_received(:move_after).with(position: "3")
      end
    end

    context "with both prev_id and position" do
      it "prefers prev_id over position" do
        allow(story).to receive(:move_after)

        instance.call(target_id: "inbox", prev_id: "5", position: "3")

        expect(story).to have_received(:move_after).with(prev_id: "5")
        expect(story).not_to have_received(:move_after).with(position: "3")
      end
    end
  end
end
