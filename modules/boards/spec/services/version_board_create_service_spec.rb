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
require_relative "base_create_service_shared_examples"

RSpec.describe Boards::VersionBoardCreateService do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  # Amount of versions is important to test that the right column count is
  # set by the service. It should set the column count to the number of versions
  # and avoid out of bounds errors.
  shared_let(:versions) { create_list(:version, 5, project:) }
  shared_let(:excluded_versions) do
    [
      create(:version, project:, status: "closed"),
      create(:version, project: other_project, sharing: "system")
    ]
  end

  shared_let(:user) { build_stubbed(:admin) }
  shared_let(:instance) { described_class.new(user:) }

  subject { instance.call(params) }

  context "with all valid params" do
    let(:params) do
      {
        name: "Gotham Renewal Board",
        project:,
        attribute: "version"
      }
    end

    it "is successful" do
      expect(subject).to be_success
    end

    it 'creates a "Version" board', :aggregate_failures do
      board = subject.result

      expect(board.name).to eq("Gotham Renewal Board")
      expect(board.options[:attribute]).to eq("version")
      expect(board.options[:type]).to eq("action")
    end

    describe "column_count" do
      it "matches the column_count to the version count" do
        board = subject.result

        expect(board.column_count).to eq(versions.count)
      end

      context "when there are no versions that apply for the project" do
        before do
          versions.each { _1.update!(status: "closed") }
        end

        it "sets the column_count to the default value" do
          board = subject.result
          expect(board.column_count).to eq(4)
        end
      end
    end

    describe "widgets and queries" do
      let(:board) { subject.result }
      let(:widgets) { board.widgets }
      let(:queries) { Query.all }

      it "creates one of each per expected version", :aggregate_failures do
        subject

        expect(widgets.count).to eq(versions.count)
        expect(queries.count).to eq(versions.count)

        expect(queries.map(&:name)).to match_array(versions.map(&:name))
      end

      it "sets the filters on each" do
        subject

        queries_filters = queries.flat_map(&:filters).map(&:to_hash)
        widgets_filters = widgets.flat_map { _1.options["filters"] }

        expect(queries_filters).to match_array(widgets_filters)
      end

      it_behaves_like "sets the appropriate sort_criteria on each query"
    end
  end
end
