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

RSpec.describe ResourceWorkPackageList do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) { create(:user) }

  subject(:view) do
    described_class.new(name: "My view", project:, principal: user).tap do |v|
      v.query = v.build_default_query
    end
  end

  def filters_json(*filters)
    filters.to_json
  end

  describe "#build_default_query" do
    it "builds a work-package Query scoped to the project and principal" do
      query = view.build_default_query

      expect(query).to be_a(Query)
      expect(query.project).to eq(project)
      expect(query.user).to eq(user)
    end
  end

  describe "#apply_query_configuration" do
    context "in automatic mode" do
      it "replaces the query filters with the serialized selection" do
        view.apply_query_configuration(
          filter_mode: "automatic",
          filters_json: filters_json({ assigned_to_id: { operator: "=", values: [user.id.to_s] } })
        )

        expect(view.query.filters.map(&:name)).to contain_exactly(:assigned_to_id)
      end

      it "names the query after the view" do
        view.apply_query_configuration(filter_mode: "automatic", filters_json: nil)

        expect(view.query.name)
          .to eq(I18n.t("resource_management.work_package_list.query_name", name: "My view"))
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
          # The hidden filter form still serializes its (ignored) default state.
          filters_json: filters_json({ status_id: { operator: "o", values: [] } })
        )
      end

      it "sets up a manual_sort filter instead of applying the submitted filters" do
        expect(view.query.filters.map(&:name)).to contain_exactly(:manual_sort)
      end

      it "switches the query to manual sorting" do
        expect(view.query).to be_manually_sorted
        expect(view).to be_manually_picked
      end
    end

    context "when switching a manual view back to automatic" do
      before do
        view.apply_query_configuration(filter_mode: "manual", filters_json: nil)
      end

      it "drops the manual sort so the query no longer depends on ordered work packages" do
        view.apply_query_configuration(
          filter_mode: "automatic",
          filters_json: filters_json({ assigned_to_id: { operator: "=", values: [user.id.to_s] } })
        )

        expect(view.query).not_to be_manually_sorted
        expect(view.query.filters.map(&:name)).to contain_exactly(:assigned_to_id)
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

  describe "validation" do
    it "is valid with a work-package query" do
      expect(view).to be_valid
    end

    it "rejects a query of the wrong type" do
      view.query = UserQuery.new(project:, principal: user)

      expect(view).not_to be_valid
      expect(view.errors).to be_added(:query, :must_be_work_package_query)
    end
  end
end
