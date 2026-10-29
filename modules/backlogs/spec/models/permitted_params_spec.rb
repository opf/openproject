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

require "rails_helper"

RSpec.describe PermittedParams do
  describe ".permitted_attributes" do
    it "permits the backlogs attributes for work packages" do
      expect(described_class.permitted_attributes[:new_work_package])
        .to include(:sprint_id, :backlog_bucket_id, :story_points)
    end
  end

  describe "#backlog_filters" do
    subject(:permitted) { described_class.new(params, build_stubbed(:user)).backlog_filters.to_h }

    context "with :bucket_ids, :sprint_ids and :all as string" do
      let(:params) do
        ActionController::Parameters.new(
          bucket_ids: %w[1 2].to_json,
          sprint_ids: %w[3].to_json,
          all: "1"
        )
      end

      it "permits all" do
        expect(permitted)
          .to eq("bucket_ids" => %w[1 2].to_json, "sprint_ids" => %w[3].to_json, "all" => "1")
      end
    end

    context "with unpermitted params" do
      let(:params) { ActionController::Parameters.new(bucket_ids: %w[1], sprint_ids: %w[1], evil: "true") }

      it "filters them out" do
        expect(permitted).to eq({})
      end
    end
  end
end
