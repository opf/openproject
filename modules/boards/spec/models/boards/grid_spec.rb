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

RSpec.describe Boards::Grid do
  let(:instance) { described_class.new }
  let(:project) { build_stubbed(:project) }

  describe "associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:linked).inverse_of(:task_boards).optional }
  end

  describe "attributes" do
    it "#project" do
      instance.project = project
      expect(instance.project)
        .to eql project
    end

    it "#name" do
      instance.name = nil

      expect(instance).not_to be_valid
      expect(instance.errors[:name]).to be_present

      instance.name = "foo"
      expect(instance).to be_valid
    end

    describe "#board_type" do
      it "extracts correct, symbolized type when it is stored as a symbol key" do
        instance.options[:type] = "action"

        expect(instance.board_type).to eq(:action)
      end

      it "extracts correct, symbolized type when it is stored as a string key" do
        instance.options["type"] = "action"

        expect(instance.board_type).to eq(:action)
      end

      it "defaults to :free type" do
        instance.options = {}

        expect(instance.board_type).to eq(:free)
      end
    end

    describe "#board_type_attribute" do
      it "returns nil for a board that is not of type action" do
        instance.options = { type: "free", attribute: "status" }

        expect(instance.board_type_attribute).to be_nil
      end

      it "returns attribute for a board that is of type action" do
        instance.options = { type: "action", attribute: "status" }

        expect(instance.board_type_attribute).to eq("status")
      end
    end
  end

  describe "#destroy" do
    context "with an associated query" do
      let(:project) { create(:project) }
      let(:instance) { described_class.new name: "foo", row_count: 2, column_count: 2, project: }
      let(:query) do
        create(:query,
               public: true,
               project: project)
      end

      current_user { build_stubbed(:user) }

      before do
        widget = Grids::Widget.new(identifier: "work_package_query",
                                   start_row: 1,
                                   end_row: 2,
                                   start_column: 1,
                                   end_column: 2,
                                   options: { "queryId" => query.id })

        instance.widgets = [widget]
        instance.save!
      end

      context "when the user has the permissions to manage queries" do
        before do
          mock_permissions_for(current_user) do |mock|
            mock.allow_in_project :manage_public_queries, project:
          end
        end

        it "deletes the query" do
          expect { instance.destroy }.to change(Query, :count).by(-1)
        end
      end

      context "when the user lacks the permissions to manage queries" do
        it "keeps the query" do
          expect { instance.destroy }.not_to change(Query, :count)
        end
      end
    end
  end
end
