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

RSpec.describe Repositories::MergeRequest do
  describe "#latest_pipeline" do
    let(:merge_request) { create(:repository_merge_request) }

    let!(:older_pipeline) { create(:repository_pipeline, merge_request:, started_at: 2.hours.ago) }
    let!(:newer_pipeline) { create(:repository_pipeline, merge_request:, started_at: 1.hour.ago) }

    it "is the pipeline that started last" do
      expect(merge_request.latest_pipeline).to eq(newer_pipeline)
    end

    context "with a pipeline that has not started yet" do
      let!(:pending_pipeline) { create(:repository_pipeline, merge_request:, started_at: nil) }

      it "is the pipeline that has not started yet" do
        expect(merge_request.latest_pipeline).to eq(pending_pipeline)
      end

      it "is also the last pipeline in chronological order" do
        expect(merge_request.pipelines.chronological).to eq([older_pipeline, newer_pipeline, pending_pipeline])
      end
    end

    context "when preloaded" do
      let!(:pending_pipeline) { create(:repository_pipeline, merge_request:, started_at: nil) }

      it "is the same pipeline" do
        expect(described_class.preload(:latest_pipeline).find(merge_request.id).latest_pipeline).to eq(pending_pipeline)
      end
    end
  end
end
