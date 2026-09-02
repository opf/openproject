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

  describe "#configuration_filters" do
    # A filter only shows up once it reports itself `available?`, so the
    # attributes it depends on have to exist for the positive assertions.
    shared_let(:status) { create(:status) }
    shared_let(:priority) { create(:issue_priority) }

    subject(:offered) { view.configuration_filters(view.build_default_query).map(&:name) }

    before do
      login_as(user)
    end

    it "offers the attributes a planner allocates by" do
      expect(offered).to include(:type_id, :status_id, :priority_id, :assigned_to_id, :responsible_id,
                                 :start_date, :due_date, :dates_interval, :estimated_hours, :done_ratio,
                                 :target_version_id)
    end

    it "withholds the project filter so it cannot override the planner's project scoping" do
      expect(offered).not_to include(:project_id)
    end

    it "withholds the filters that back autocompleters and full-text search" do
      expect(offered).not_to include(:typeahead, :search, :subject_or_id, :relatable,
                                     :attachment_content, :attachment_file_name,
                                     :description, :comment)
    end

    it "withholds the storage integration filters" do
      expect(offered).not_to include(:storage_id, :storage_url, :linkable_to_storage_id,
                                     :linkable_to_storage_url, :file_link_origin_id)
    end

    it "withholds the relation filters" do
      expect(offered).not_to include(:precedes, :follows, :relates, :blocks, :blocked,
                                     :duplicates, :duplicated, :partof, :includes,
                                     :requires, :required)
    end

    it "sorts them by their human name so the picker reads alphabetically" do
      names = view.configuration_filters(view.build_default_query).map(&:human_name)

      expect(names).to eq(names.sort)
    end

    it "returns nothing without a query" do
      expect(view.configuration_filters(nil)).to be_empty
    end

    context "with an active work package custom field" do
      shared_let(:custom_field) do
        create(:work_package_custom_field, field_format: "string", is_for_all: true, is_filter: true)
      end

      before do
        project.work_package_custom_fields << custom_field
        project.enabled_variants.each { |variant| variant.custom_fields << custom_field }
      end

      it "offers it alongside the built-in attributes" do
        expect(offered).to include(:"cf_#{custom_field.id}")
      end
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

      it "ignores a withheld project filter so the project scoping cannot be overridden" do
        view.apply_query_configuration(
          filter_mode: "automatic",
          filters_json: filters_json({ project_id: { operator: "=", values: ["999"] } },
                                     { assigned_to_id: { operator: "=", values: [user.id.to_s] } })
        )

        expect(view.query.filters.map(&:name)).to contain_exactly(:assigned_to_id)
      end

      it "ignores any other filter the configuration UI does not offer" do
        view.apply_query_configuration(
          filter_mode: "automatic",
          filters_json: filters_json({ watcher_id: { operator: "=", values: [user.id.to_s] } },
                                     { linkable_to_storage_id: { operator: "=", values: ["1"] } },
                                     { assigned_to_id: { operator: "=", values: [user.id.to_s] } })
        )

        expect(view.query.filters.map(&:name)).to contain_exactly(:assigned_to_id)
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

  describe "#allocation_work_package_filters" do
    context "in automatic mode" do
      before do
        view.apply_query_configuration(
          filter_mode: "automatic",
          filters_json: filters_json({ assigned_to_id: { operator: "=", values: [user.id.to_s] } })
        )
      end

      it "forwards the view's query filters so the API filters server-side" do
        expect(view.allocation_work_package_filters).to contain_exactly(
          { name: "assigned_to_id", operator: "=", values: [user.id.to_s] }
        )
      end
    end

    context "in manual mode" do
      let(:picked) { create(:work_package, project:) }

      before do
        create(:member, principal: user, project:,
                        roles: [create(:project_role, permissions: %i[view_work_packages])])
        login_as(user)
        view.apply_query_configuration(filter_mode: "manual", filters_json: nil)
        view.query.save!
        view.query.ordered_work_packages.create!(work_package: picked, position: 1)
      end

      it "pins the hand-picked work package ids rather than a huge filter set" do
        filters = view.allocation_work_package_filters

        expect(filters.size).to eq(1)
        expect(filters.first).to include(name: "id", operator: "=")
        expect(filters.first[:values]).to contain_exactly(picked.id.to_s)
      end
    end

    it "leaves the user picker unconstrained" do
      expect(view.allocation_principal_filters).to be_nil
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
