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

RSpec.describe API::V3::AI::TextTransformRunRepresenter do
  include API::V3::Utilities::PathHelper

  shared_let(:user) { create(:user) }

  let(:run) { create(:ai_text_transform_run, user:) }
  let(:after) { 0 }
  let(:representer) { described_class.new(run, current_user: user, after:) }

  subject(:generated) { representer.to_json }

  before do
    run.append_event("status", status: "running")
    run.append_event("text_delta", delta: "The ")
    run.append_event("completed", text: "The login")
  end

  it_behaves_like "property", :_type do
    let(:value) { "AITextTransformRun" }
  end

  it_behaves_like "property", :id do
    let(:value) { run.uuid }
  end

  it_behaves_like "property", :status do
    let(:value) { "queued" }
  end

  it_behaves_like "property", :systemPrompt do
    let(:value) { run.system_prompt }
  end

  it_behaves_like "no property", :uuid

  describe "events" do
    it "lists every event with seq, kind and payload" do
      expect(generated).to be_json_eql(
        [
          { seq: 1, kind: "status", payload: { status: "running" } },
          { seq: 2, kind: "text_delta", payload: { delta: "The " } },
          { seq: 3, kind: "completed", payload: { text: "The login" } }
        ].to_json
      ).at_path("events")
    end

    context "with a cursor" do
      let(:after) { 2 }

      it "lists only the events after the cursor" do
        expect(generated).to be_json_eql(
          [{ seq: 3, kind: "completed", payload: { text: "The login" } }].to_json
        ).at_path("events")
      end
    end
  end

  describe "_links" do
    it "links to itself by uuid without a title" do
      expect(generated)
        .to be_json_eql(api_v3_paths.ai_text_transform_run(run.uuid).to_json).at_path("_links/self/href")
      expect(generated).not_to have_json_path("_links/self/title")
    end

    it "links to cancel while the run is not terminal" do
      expect(generated)
        .to be_json_eql(api_v3_paths.ai_text_transform_run_cancel(run.uuid).to_json).at_path("_links/cancel/href")
      expect(generated).to be_json_eql("post".to_json).at_path("_links/cancel/method")
    end

    AI::TextTransformRun::TERMINAL_STATUSES.each do |status|
      context "with a #{status} run" do
        let(:run) { create(:ai_text_transform_run, status.to_sym, user:) }

        it "has no cancel link" do
          expect(generated).not_to have_json_path("_links/cancel")
        end
      end
    end
  end
end
