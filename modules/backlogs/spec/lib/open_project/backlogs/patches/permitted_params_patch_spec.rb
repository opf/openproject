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

RSpec.describe PermittedParams do
  let(:user) { build_stubbed(:user) }

  describe "#update_work_package" do
    subject(:permitted) { described_class.new(params, user).update_work_package.to_h }

    context "with sprint_id" do
      let(:params) { ActionController::Parameters.new(work_package: { sprint_id: "1" }) }

      it "permits it" do
        expect(permitted).to eq("sprint_id" => "1")
      end
    end

    context "with backlog_bucket_id" do
      let(:params) { ActionController::Parameters.new(work_package: { backlog_bucket_id: "1" }) }

      it "permits it" do
        expect(permitted).to eq("backlog_bucket_id" => "1")
      end
    end

    context "with story_points" do
      let(:params) { ActionController::Parameters.new(work_package: { story_points: "5" }) }

      it "permits it" do
        expect(permitted).to eq("story_points" => "5")
      end
    end
  end

  describe "#backlog_filters" do
    subject(:permitted) { described_class.new(params, user).backlog_filters.to_h }

    context "with bucket_ids and sprint_ids" do
      let(:params) { ActionController::Parameters.new(bucket_ids: %w[1 2], sprint_ids: %w[3]) }

      it "permits both arrays" do
        expect(permitted).to eq("bucket_ids" => %w[1 2], "sprint_ids" => %w[3])
      end
    end

    context "with bucket_ids and sprint_ids as compact comma-delimited strings" do
      let(:params) { ActionController::Parameters.new(bucket_ids: "1,2", sprint_ids: "3") }

      it "permits both strings" do
        expect(permitted).to eq("bucket_ids" => "1,2", "sprint_ids" => "3")
      end
    end

    context "with the all flag" do
      let(:params) { ActionController::Parameters.new(all: "1") }

      it "permits all" do
        expect(permitted).to eq("all" => "1")
      end
    end

    context "with bucket_ids as a hash (e.g. bucket_ids[0]=1)" do
      let(:params) { ActionController::Parameters.new(bucket_ids: { "0" => "1", "1" => "2" }) }

      it "filters it out" do
        expect(permitted).to eq({})
      end
    end

    context "with unpermitted params" do
      let(:params) { ActionController::Parameters.new(bucket_ids: %w[1], evil: "true") }

      it "filters them out" do
        expect(permitted).to eq("bucket_ids" => %w[1])
      end
    end
  end
end
