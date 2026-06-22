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

require "rails_helper"

RSpec.describe Backlogs::CommonHelper do
  current_user { build_stubbed(:user) }

  let(:params) { {} }

  before do
    allow(helper).to receive(:params).and_return(ActionController::Parameters.new(params))
  end

  describe "#user_allowed?" do
    let(:default_project) { build_stubbed(:project) }
    let(:explicit_project) { build_stubbed(:project) }

    before do
      without_partial_double_verification do
        allow(helper).to receive_messages(current_user:, project: default_project)
      end

      mock_permissions_for(current_user) do |mock|
        mock.allow_in_project(:create_sprints, project: explicit_project)
      end
    end

    it "checks permissions in the provided project when given" do
      expect(helper.user_allowed?(:create_sprints, project: explicit_project)).to be true
    end

    it "checks permissions in the default project when none is given" do
      expect(helper.user_allowed?(:create_sprints)).to be false
    end
  end

  describe "#backlog_filters" do
    context "with no params" do
      let(:params) { {} }

      it "returns filters with empty to_h" do
        expect(helper.backlog_filters.to_h).to eq({})
      end
    end

    context "with all: '1'" do
      let(:params) { { all: "1" } }

      it "returns filters with all: true in to_h" do
        expect(helper.backlog_filters.to_h).to eq({ all: true })
      end
    end

    context "with bucket_ids and sprint_ids" do
      let(:params) { { bucket_ids: %w[1 2], sprint_ids: %w[3] } }

      it "includes both in to_h" do
        expect(helper.backlog_filters.to_h).to eq({ bucket_ids: [1, 2], sprint_ids: [3] })
      end
    end

    context "with bucket_ids as a hash (e.g. bucket_ids[0]=1)" do
      let(:params) { { bucket_ids: { "0" => "1" } } }

      it "filters out the hash-form bucket_ids" do
        expect(helper.backlog_filters.bucket_ids).to be_nil
      end
    end
  end

  describe "#backlog_filter_params" do
    let(:params) { { bucket_ids: %w[1 2], all: "1" } }

    it "returns the same hash as backlog_filters.to_h" do
      expect(helper.backlog_filter_params).to eq(helper.backlog_filters.to_h)
    end
  end

  describe "#filtered_buckets_for" do
    let(:project) { create(:project) }
    let!(:bucket_a) { create(:backlog_bucket, project:) }
    let!(:bucket_b) { create(:backlog_bucket, project:) }

    context "with no bucket_ids filter" do
      let(:params) { {} }

      it "returns all buckets for the project" do
        expect(helper.filtered_buckets_for(project)).to contain_exactly(bucket_a, bucket_b)
      end
    end

    context "when only inbox is selected" do
      let(:params) { { bucket_ids: ["inbox"] } }

      it "returns no buckets" do
        expect(helper.filtered_buckets_for(project)).to be_empty
      end
    end

    context "when inbox and a specific bucket are selected" do
      let(:params) { { bucket_ids: [bucket_a.id.to_s, "inbox"] } }

      it "returns only the selected bucket" do
        expect(helper.filtered_buckets_for(project)).to contain_exactly(bucket_a)
      end
    end

    context "when only specific bucket IDs are selected" do
      let(:params) { { bucket_ids: [bucket_a.id.to_s] } }

      it "returns only the matching bucket" do
        expect(helper.filtered_buckets_for(project)).to contain_exactly(bucket_a)
      end
    end
  end
end
