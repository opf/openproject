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

RSpec.describe ResourceUserCard do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_resource_planners],
             other_project => %i[view_resource_planners]
           })
  end
  shared_let(:member) do
    create(:user, firstname: "Mary", lastname: "Member",
                  member_with_permissions: { project => %i[view_resource_planners] })
  end
  # Visible to `user` through the shared other project, but not a member of
  # `project` - to test project based visibility
  shared_let(:non_member) do
    create(:user, firstname: "Otto", lastname: "Outsider",
                  member_with_permissions: { other_project => %i[view_resource_planners] })
  end

  subject(:view) do
    described_class.new(name: "My view", project:, principal: user).tap do |v|
      v.query = v.build_default_query
    end
  end

  def filters_json(*filters)
    filters.to_json
  end

  describe "#build_default_query" do
    it "builds a user Query scoped to the project and user" do
      query = view.build_default_query

      expect(query).to be_a(UserQuery)
      expect(query.project).to eq(project)
      expect(query.user).to eq(user)
    end
  end

  describe "#apply_query_configuration" do
    context "in automatic mode" do
      it "replaces the query filters with the automatic selection" do
        view.apply_query_configuration(
          filter_mode: "automatic",
          filters_json: filters_json({ status: { operator: "=", values: ["active"] } })
        )

        expect(view.query.filters.map(&:name)).to contain_exactly(:status)
      end

      it "tolerates an invalid JSON payload by applying no filters" do
        view.apply_query_configuration(filter_mode: "automatic", filters_json: "not json")

        expect(view.query.filters).to be_empty
      end

      it "is not manually picked" do
        view.apply_query_configuration(filter_mode: "automatic", filters_json: nil)

        expect(view).not_to be_manually_picked
      end
    end

    context "in manual mode" do
      before do
        view.apply_query_configuration(
          filter_mode: "manual",
          # The hidden filter form ignores filters in manual mode
          filters_json: filters_json({ status: { operator: "=", values: ["active"] } })
        )
      end

      it "marks the view as manually picked" do
        expect(view).to be_manually_picked
      end

      it "clears the filters instead of applying the submitted selection" do
        expect(view.query.filters).to be_empty
      end
    end

    context "when switching a manual view back to automatic" do
      before do
        view.apply_query_configuration(filter_mode: "manual", filters_json: nil)
        view.query.save!
        view.query.ordered_entities.create!(entity: member, position: 1)
      end

      it "clears the manually-picked entities" do
        view.apply_query_configuration(filter_mode: "automatic", filters_json: nil)

        expect(view).not_to be_manually_picked
        expect(view.query.ordered_entities).to be_empty
      end
    end

    context "without a query" do
      subject(:view) { described_class.new(name: "My view", project:, principal: user) }

      it "does nothing" do
        expect { view.apply_query_configuration(filter_mode: "manual", filters_json: nil) }
          .not_to raise_error
      end
    end
  end

  describe "#results" do
    before { login_as(user) }

    context "in automatic mode" do
      it "returns the project members and excludes non-members" do
        expect(view.results).to include(user, member)
        expect(view.results).not_to include(non_member)
      end
    end

    context "in manual mode" do
      before do
        view.apply_query_configuration(filter_mode: "manual", filters_json: nil)
        view.query.save!
      end

      it "returns an empty set until users are added" do
        expect(view.results).to be_empty
      end

      context "with hand-picked users" do
        before do
          view.query.ordered_entities.create!(entity: member, position: 1)
          view.query.ordered_entities.create!(entity: non_member, position: 2)
        end

        it "returns only the picked users still belonging to the project" do
          expect(view.results).to contain_exactly(member)
        end
      end
    end
  end

  describe "#card_fields" do
    it "defaults a new view to department and working times" do
      expect(described_class.new.card_fields).to eq(%w[department working_times])
    end

    it "round-trips an ordered selection through the options column" do
      view.card_fields = %w[working_times cf_5 department]
      view.save!

      expect(view.reload.card_fields).to eq(%w[working_times cf_5 department])
    end

    it "preserves an explicitly emptied selection instead of re-defaulting" do
      view.card_fields = []
      view.save!

      expect(view.reload.card_fields).to eq([])
    end
  end

  describe "validation" do
    it "is valid with a user query" do
      expect(view).to be_valid
    end

    it "rejects a query of the wrong type" do
      view.query = Query.new(project:, user:)

      expect(view).not_to be_valid
      expect(view.errors).to be_added(:query, :invalid)
    end
  end
end
