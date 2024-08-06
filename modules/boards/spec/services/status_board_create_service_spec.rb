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

RSpec.describe Boards::StatusBoardCreateService do
  shared_let(:project) { create(:project) }
  shared_let(:status) { create(:default_status) }
  shared_let(:user) { build_stubbed(:admin) }
  shared_let(:instance) { described_class.new(user:) }

  subject { instance.call(params) }

  context "with all valid params" do
    let(:params) do
      {
        name: "Gotham Renewal Board",
        project:,
        attribute: "status"
      }
    end

    it "is successful" do
      expect(subject).to be_success
    end

    it 'creates a "Status" board', :aggregate_failures do
      board = subject.result

      expect(board.name).to eq("Gotham Renewal Board")
      expect(board.options[:attribute]).to eq("status")
      expect(board.options[:type]).to eq("action")
    end

    describe "widgets and queries" do
      let(:board) { subject.result }
      let(:widgets) { board.widgets }
      let(:queries) { Query.all }

      it "creates one of each for the current default status", :aggregate_failures do
        subject

        expect(widgets.count).to eq 1
        expect(queries.count).to eq 1
      end

      it "sets the filters on each" do
        subject

        query_filter = queries.flat_map(&:filters).map(&:to_hash).first
        widget_filter = widgets.flat_map { _1.options["filters"] }.first

        expect(query_filter).to match_array(widget_filter)
      end

      it_behaves_like "sets the appropriate sort_criteria on each query"
    end
  end
end
