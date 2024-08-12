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

RSpec.describe Projects::GanttQueryGeneratorService, type: :model do
  let(:selected) { %w[1 2 3] }
  let(:instance) { described_class.new selected }
  let(:subject) { instance.call }
  let(:json) { JSON.parse(subject) }
  let(:milestone_ids) { [123, 234] }
  let(:default_json) do
    scope = double("scope")
    allow(Type)
      .to receive(:milestone)
      .and_return(scope)

    allow(scope)
      .to receive(:pluck)
      .with(:id)
      .and_return(milestone_ids)

    JSON
      .parse(Projects::GanttQueryGeneratorService::DEFAULT_GANTT_QUERY)
      .merge("f" => [{ "n" => "type", "o" => "=", "v" => milestone_ids.map(&:to_s) }])
  end

  def build_project_filter(ids)
    { "n" => "project", "o" => "=", "v" => ids }
  end

  context "with empty setting" do
    before do
      Setting.project_gantt_query = ""
    end

    it "uses the default" do
      expected = default_json.deep_dup
      expected["f"] << build_project_filter(selected)
      expect(json).to eq(expected)
    end

    context "without configured milestones" do
      let(:milestone_ids) { [] }

      it "uses the default but without the type filter" do
        expected = default_json
                     .deep_dup
                     .merge("f" => [build_project_filter(selected)])
        expect(json).to eq(expected)
      end
    end
  end

  context "with existing filter" do
    it "overrides the filter" do
      Setting.project_gantt_query = default_json.deep_dup.merge("f" => [build_project_filter(%w[other values])]).to_json

      expected = default_json.deep_dup.merge("f" => [build_project_filter(selected)])
      expect(json).to eq(expected)
    end
  end

  context "with invalid json" do
    it "returns the default" do
      Setting.project_gantt_query = "invalid!1234"

      expected = default_json.deep_dup
      expected["f"] << build_project_filter(selected)
      expect(json).to eq(expected)
    end
  end
end
