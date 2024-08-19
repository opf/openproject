# -- copyright
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
# ++

require "spec_helper"
require "services/base_services/behaves_like_create_service"

RSpec.describe Queries::Projects::Factory,
               with_settings: { enabled_projects_columns: %w[favored name project_status] } do
  before do
    scope = instance_double(ActiveRecord::Relation)

    allow(ProjectQuery)
      .to receive(:visible)
            .with(current_user)
            .and_return(scope)

    allow(scope)
      .to receive(:find_by)
            .with(id:)
            .and_return(persisted_query)
  end

  let(:persisted_query) do
    build_stubbed(:project_query, name: "My query") do |query|
      query.order(id: :asc)
      query.where(:project_status_code, "=", [Project.status_codes[:on_track].to_s])
      query.select(:project_status, :name, :favored)
    end
  end
  let(:custom_field) do
    build_stubbed(:project_custom_field, id: 1) do |cf|
      scope = instance_double(ActiveRecord::Relation)

      allow(ProjectCustomField)
        .to receive(:visible)
              .and_return(scope)

      allow(scope)
        .to receive(:find_by)
              .and_return nil

      allow(scope)
        .to receive(:find_by)
              .with(id: cf.id.to_s)
              .and_return(cf)
    end
  end

  let(:id) { nil }
  let(:params) { {} }
  let(:default_selects) do
    Setting.enabled_projects_columns.map(&:to_sym)
  end

  current_user { build_stubbed(:user) }

  describe ".find" do
    subject(:find) { described_class.find(id, params:, user: current_user, duplicate:) }

    let(:duplicate) { false }

    context "without id" do
      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has a name" do
        expect(find.name)
          .to eql(I18n.t("projects.lists.active"))
      end

      it "has a filter for active projects" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:active, "=", ["t"]]])
      end

      it "is ordered by lft asc" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[lft asc]])
      end

      it "has the enabled_project_columns columns as selects" do
        expect(find.selects.map(&:attribute))
          .to eq(default_selects)
      end

      it { is_expected.not_to be_changed }
    end

    context "without id and with ee and admin privileges",
            with_settings: { enabled_projects_columns: %w[name created_at cf_1] } do
      current_user { build_stubbed(:admin) }

      before do
        custom_field
      end

      it "has the enabled_project_columns columns as selects" do
        expect(find.selects.map(&:attribute))
          .to eq(default_selects)
      end

      it { is_expected.not_to be_changed }
    end

    context "with the 'active' id" do
      let(:id) { "active" }

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has a name" do
        expect(find.name)
          .to eql(I18n.t("projects.lists.active"))
      end

      it "has a filter for active projects" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:active, "=", ["t"]]])
      end

      it "is ordered by lft asc" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[lft asc]])
      end

      it "has the enabled_project_columns columns as selects" do
        expect(find.selects.map(&:attribute))
          .to eq(default_selects)
      end

      it { is_expected.not_to be_changed }
    end

    context "with the 'my' id" do
      let(:id) { "my" }

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has a name" do
        expect(find.name)
          .to eql(I18n.t("projects.lists.my"))
      end

      it "has a filter for projects the user is a member of" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:member_of, "=", ["t"]]])
      end

      it "is ordered by lft asc" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[lft asc]])
      end

      it "has the enabled_project_columns columns as selects" do
        expect(find.selects.map(&:attribute))
          .to eq(default_selects)
      end

      it { is_expected.not_to be_changed }
    end

    context "with the 'archived' id" do
      let(:id) { "archived" }

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has a name" do
        expect(find.name)
          .to eql(I18n.t("projects.lists.archived"))
      end

      it "has a filter for archived projects" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:active, "=", ["f"]]])
      end

      it "is ordered by lft asc" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[lft asc]])
      end

      it "has the enabled_project_columns columns as selects" do
        expect(find.selects.map(&:attribute))
          .to eq(default_selects)
      end

      it { is_expected.not_to be_changed }
    end

    context "with the 'on_track' id" do
      let(:id) { "on_track" }

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has a name" do
        expect(find.name)
          .to eql(I18n.t("activerecord.attributes.project.status_codes.on_track"))
      end

      it 'has a filter for projects that are "on track"' do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:project_status_code, "=", [Project.status_codes[:on_track].to_s]]])
      end

      it "is ordered by lft asc" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[lft asc]])
      end

      it "has the enabled_project_columns columns as selects" do
        expect(find.selects.map(&:attribute))
          .to eq(default_selects)
      end

      it { is_expected.not_to be_changed }
    end

    context "with the 'off_track' id" do
      let(:id) { "off_track" }

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has a name" do
        expect(find.name)
          .to eql(I18n.t("activerecord.attributes.project.status_codes.off_track"))
      end

      it 'has a filter for projects that are "off track"' do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:project_status_code, "=", [Project.status_codes[:off_track].to_s]]])
      end

      it "is ordered by lft asc" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[lft asc]])
      end

      it "has the enabled_project_columns columns as selects" do
        expect(find.selects.map(&:attribute))
          .to eq(default_selects)
      end

      it { is_expected.not_to be_changed }
    end

    context "with the 'at_risk' id" do
      let(:id) { "at_risk" }

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has a name" do
        expect(find.name)
          .to eql(I18n.t("activerecord.attributes.project.status_codes.at_risk"))
      end

      it 'has a filter for projects that are "at risk"' do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:project_status_code, "=", [Project.status_codes[:at_risk].to_s]]])
      end

      it "is ordered by lft asc" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[lft asc]])
      end

      it "has the enabled_project_columns columns as selects" do
        expect(find.selects.map(&:attribute))
          .to eq(default_selects)
      end

      it { is_expected.not_to be_changed }
    end

    context "with an integer id for which the user has a query" do
      let(:id) { 42 }

      it "returns the persisted query" do
        expect(find)
          .to eql(persisted_query)
      end

      it "has a name" do
        expect(find.name)
          .to eql("My query")
      end

      it 'has a filter for projects that are "at risk"' do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:project_status_code, "=", [Project.status_codes[:on_track].to_s]]])
      end

      it "is ordered by lft asc" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[id asc]])
      end

      it "has the enabled_project_columns columns as selects" do
        expect(find.selects.map(&:attribute))
          .to eq(%i[project_status name favored])
      end

      it { is_expected.not_to be_changed }
    end

    context "with an integer id for which the user does not have a persisted query" do
      let(:id) { 42 }
      let(:persisted_query) { nil }

      it "returns nil" do
        expect(find)
          .to be_nil
      end
    end

    context "without an id and with params" do
      let(:id) { nil }
      let(:params) do
        {
          filters: [
            {
              attribute: "active",
              operator: "=",
              values: ["f"]
            },
            {
              attribute: "member_of",
              operator: "=",
              values: ["t"]
            }
          ],
          orders: [
            {
              attribute: "id",
              direction: "asc"
            },
            {
              attribute: "name",
              direction: "desc"
            }
          ],
          selects: %w[description name]
        }
      end

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has no name" do
        expect(find.name)
          .to be_nil
      end

      it "has the filters applied" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:active, "=", ["f"]], [:member_of, "=", ["t"]]])
      end

      it "has the orders applied" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([["id", :asc], ["name", :desc]])
      end

      it "has the selects" do
        expect(find.selects.map(&:attribute))
          .to eq(%i[description name])
      end

      it { is_expected.to be_changed }
    end

    context "when duplicating without an id" do
      let(:id) { nil }
      let(:duplicate) { true }

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has no name" do
        expect(find.name)
          .to be_nil
      end

      it { is_expected.to be_new_record }

      it "has a filter for active projects" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:active, "=", ["t"]]])
      end

      it "is ordered by lft asc" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[lft asc]])
      end

      it "has the enabled_project_columns columns as selects" do
        expect(find.selects.map(&:attribute))
          .to eq(default_selects)
      end

      it { is_expected.to be_changed }
    end

    context "with the 'active' id and with order params" do
      let(:id) { "active" }
      let(:params) do
        {
          orders: [
            {
              attribute: "id",
              direction: "asc"
            },
            {
              attribute: "name",
              direction: "desc"
            }
          ]
        }
      end

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has no name" do
        expect(find.name)
          .to be_nil
      end

      it "has the filters of the default 'active' query applied" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:active, "=", ["t"]]])
      end

      it "has the orders overwritten" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([["id", :asc], ["name", :desc]])
      end

      it "has the enabled_project_columns columns as selects" do
        expect(find.selects.map(&:attribute))
          .to eq(default_selects)
      end

      it { is_expected.to be_changed }
    end

    context "with the 'active' id and with filter params" do
      let(:id) { "active" }
      let(:params) do
        {
          filters: [
            {
              attribute: "active",
              operator: "=",
              values: ["f"]
            },
            {
              attribute: "member_of",
              operator: "=",
              values: ["t"]
            }
          ]
        }
      end

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has no name" do
        expect(find.name)
          .to be_nil
      end

      it "has the filters overwritten" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:active, "=", ["f"]], [:member_of, "=", ["t"]]])
      end

      it "has the orders of the default 'active' query applied" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[lft asc]])
      end

      it "has the enabled_project_columns columns as selects" do
        expect(find.selects.map(&:attribute))
          .to eq(default_selects)
      end

      it { is_expected.to be_changed }
    end

    context "with the 'active' id and with select params" do
      let(:id) { "active" }
      let(:params) do
        {
          selects: %w[description project_status]
        }
      end

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has no name" do
        expect(find.name)
          .to be_nil
      end

      it "has the filters of the default 'active' query applied" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:active, "=", ["t"]]])
      end

      it "has the orders of the default 'active' query applied" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[lft asc]])
      end

      it "has the selects overwritten" do
        expect(find.selects.map(&:attribute))
          .to eq(%i[description project_status])
      end

      it { is_expected.to be_changed }
    end

    context "when duplicating with the 'active' id" do
      let(:id) { "active" }
      let(:duplicate) { true }

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has no name" do
        expect(find.name)
          .to be_nil
      end

      it { is_expected.to be_new_record }

      it "has a filter for active projects" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:active, "=", ["t"]]])
      end

      it "is ordered by lft asc" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[lft asc]])
      end

      it "has the enabled_project_columns columns as selects" do
        expect(find.selects.map(&:attribute))
          .to eq(default_selects)
      end

      it { is_expected.to be_changed }
    end

    context "with an integer id for which the user has a query and with filter params" do
      let(:id) { 42 }
      let(:params) do
        {
          filters: [
            {
              attribute: "active",
              operator: "=",
              values: ["f"]
            },
            {
              attribute: "member_of",
              operator: "=",
              values: ["t"]
            }
          ]
        }
      end

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "keeps the name" do
        expect(find.name)
          .to eql(persisted_query.name)
      end

      it "has the filters overwritten" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:active, "=", ["f"]], [:member_of, "=", ["t"]]])
      end

      it "has the orders of the persisted query" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[id asc]])
      end

      it "has the selects of the persisted query" do
        expect(find.selects.map(&:attribute))
          .to eq(%i[project_status name favored])
      end

      it { is_expected.to be_changed }
    end

    context "with an integer id for which the user has a query and with order params" do
      let(:id) { 42 }
      let(:params) do
        {
          orders: [
            {
              attribute: "id",
              direction: "asc"
            },
            {
              attribute: "name",
              direction: "desc"
            }
          ]
        }
      end

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "keeps the name" do
        expect(find.name)
          .to eql(persisted_query.name)
      end

      it "has the filters of the persisted query" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:project_status_code, "=", [Project.status_codes[:on_track].to_s]]])
      end

      it "has the orders overwritten" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq [["id", :asc], ["name", :desc]]
      end

      it "has the selects of the persisted query" do
        expect(find.selects.map(&:attribute))
          .to eq(%i[project_status name favored])
      end

      it { is_expected.to be_changed }
    end

    context "with an integer id for which the user has a query and with select params" do
      let(:id) { 42 }
      let(:params) do
        {
          selects: %w[description project_status]
        }
      end

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "keeps the name" do
        expect(find.name)
          .to eql(persisted_query.name)
      end

      it "has the filters of the persisted query" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:project_status_code, "=", [Project.status_codes[:on_track].to_s]]])
      end

      it "has the orders of the persisted query" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[id asc]])
      end

      it "has the selects specified by the params" do
        expect(find.selects.map(&:attribute))
          .to eq(%i[description project_status])
      end

      it { is_expected.to be_changed }
    end

    context "with an integer id for which the user does not have a query and with params" do
      let(:id) { 42 }
      let(:persisted_query) { nil }
      let(:params) do
        {
          filters: [
            {
              attribute: "active",
              operator: "=",
              values: ["f"]
            },
            {
              attribute: "member_of",
              operator: "=",
              values: ["t"]
            }
          ],
          orders: [
            {
              attribute: "id",
              direction: "asc"
            },
            {
              attribute: "name",
              direction: "desc"
            }
          ]
        }
      end

      it "returns nil" do
        expect(find)
          .to be_nil
      end
    end

    context "when duplicating with an integer id" do
      let(:id) { 42 }
      let(:duplicate) { true }

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "has no name" do
        expect(find.name)
          .to be_nil
      end

      it { is_expected.to be_new_record }

      it "keeps filters" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:project_status_code, "=", [Project.status_codes[:on_track].to_s]]])
      end

      it "keeps ordereds" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq([%i[id asc]])
      end

      it "keeps selects" do
        expect(find.selects.map(&:attribute))
          .to eq(%i[project_status name favored])
      end

      it { is_expected.to be_changed }
    end

    context "without id, as non admin and with a non existing custom field id",
            with_settings: { enabled_projects_columns: %w[name created_at cf_1 cf_42] } do
      before do
        custom_field
      end

      it "has only the available fields (non admin only and only existing cf)" do
        expect(find.selects.map(&:attribute))
          .to eq(%i[name cf_1]) # rubocop:disable Naming/VariableNumber
      end

      it { is_expected.not_to be_changed }
    end

    context "with an integer id with non existing selects, filters and orders" do
      let(:id) { persisted_query.id }

      let(:persisted_query) do
        build_stubbed(:project_query) do |query|
          query.order(id: :asc, blubs: :desc)
          query.where(:project_status_code, "=", [Project.status_codes[:on_track].to_s])
          query.where(:blubs, "=", [123])
          query.select(:project_status, :name, :blubs)
        end
      end

      it "returns a project query" do
        expect(find)
          .to be_a(ProjectQuery)
      end

      it "keeps the name" do
        expect(find.name)
          .to eql(persisted_query.name)
      end

      it "has the filters of the persisted query reduced to the valid ones" do
        expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
          .to eq([[:project_status_code, "=", [Project.status_codes[:on_track].to_s]]])
      end

      it "has the orders reduced to the valid ones" do
        expect(find.orders.map { |order| [order.attribute, order.direction] })
          .to eq [%i[id asc]]
      end

      it "has the selects reduced to the valid ones" do
        expect(find.selects.map(&:attribute))
          .to eq(%i[project_status name])
      end

      it { is_expected.not_to be_changed }

      context "when params are changing an attribute" do
        let(:params) { { selects: %w[description project_status] } }

        it { is_expected.to be_changed }
      end

      context "when params are changing an attribute to invalid value" do
        let(:params) { { selects: %w[project_status name blubs] } }

        it { is_expected.to be_changed }
      end

      context "when params are changing an attribute to valid subset" do
        let(:params) { { selects: %w[project_status name] } }

        it { is_expected.not_to be_changed }
      end
    end
  end

  describe ".static_query_active" do
    subject(:find) { described_class.static_query_active }

    it "returns a project query" do
      expect(find)
        .to be_a(ProjectQuery)
    end

    it "has a name" do
      expect(find.name)
        .to eql(I18n.t("projects.lists.active"))
    end

    it "has a filter for active projects" do
      expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
        .to eq([[:active, "=", ["t"]]])
    end

    it "is ordered by lft asc" do
      expect(find.orders.map { |order| [order.attribute, order.direction] })
        .to eq([%i[lft asc]])
    end

    it "has the enabled_project_columns columns as selects" do
      expect(find.selects.map(&:attribute))
        .to eq(default_selects)
    end
  end

  describe ".static_query_my" do
    subject(:find) { described_class.static_query_my }

    it "returns a project query" do
      expect(find)
        .to be_a(ProjectQuery)
    end

    it "has a name" do
      expect(find.name)
        .to eql(I18n.t("projects.lists.my"))
    end

    it "has a filter for projects the user is a member of" do
      expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
        .to eq([[:member_of, "=", ["t"]]])
    end

    it "is ordered by lft asc" do
      expect(find.orders.map { |order| [order.attribute, order.direction] })
        .to eq([%i[lft asc]])
    end

    it "has the enabled_project_columns columns as selects" do
      expect(find.selects.map(&:attribute))
        .to eq(default_selects)
    end
  end

  describe ".static_query_archived" do
    subject(:find) { described_class.static_query_archived }

    it "returns a project query" do
      expect(find)
        .to be_a(ProjectQuery)
    end

    it "has a name" do
      expect(find.name)
        .to eql(I18n.t("projects.lists.archived"))
    end

    it "has a filter for archived projects" do
      expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
        .to eq([[:active, "=", ["f"]]])
    end

    it "is ordered by lft asc" do
      expect(find.orders.map { |order| [order.attribute, order.direction] })
        .to eq([%i[lft asc]])
    end

    it "has the enabled_project_columns columns as selects" do
      expect(find.selects.map(&:attribute))
        .to eq(default_selects)
    end
  end

  describe ".static_query_status_on_track" do
    subject(:find) { described_class.static_query_status_on_track }

    it "returns a project query" do
      expect(find)
        .to be_a(ProjectQuery)
    end

    it "has a name" do
      expect(find.name)
        .to eql(I18n.t("activerecord.attributes.project.status_codes.on_track"))
    end

    it 'has a filter for project that are "on track"' do
      expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
        .to eq([[:project_status_code, "=", [Project.status_codes[:on_track].to_s]]])
    end

    it "is ordered by lft asc" do
      expect(find.orders.map { |order| [order.attribute, order.direction] })
        .to eq([%i[lft asc]])
    end

    it "has the enabled_project_columns columns as selects" do
      expect(find.selects.map(&:attribute))
        .to eq(default_selects)
    end
  end

  describe ".static_query_status_off_track" do
    subject(:find) { described_class.static_query_status_off_track }

    it "returns a project query" do
      expect(find)
        .to be_a(ProjectQuery)
    end

    it "has a name" do
      expect(find.name)
        .to eql(I18n.t("activerecord.attributes.project.status_codes.off_track"))
    end

    it 'has a filter for projects that are "off track"' do
      expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
        .to eq([[:project_status_code, "=", [Project.status_codes[:off_track].to_s]]])
    end

    it "is ordered by lft asc" do
      expect(find.orders.map { |order| [order.attribute, order.direction] })
        .to eq([%i[lft asc]])
    end

    it "has the enabled_project_columns columns as selects" do
      expect(find.selects.map(&:attribute))
        .to eq(default_selects)
    end
  end

  describe ".static_query_status_at_risk" do
    subject(:find) { described_class.static_query_status_at_risk }

    it "returns a project query" do
      expect(find)
        .to be_a(ProjectQuery)
    end

    it "has a name" do
      expect(find.name)
        .to eql(I18n.t("activerecord.attributes.project.status_codes.at_risk"))
    end

    it 'has a filter for projects that are "at risk"' do
      expect(find.filters.map { |filter| [filter.field, filter.operator, filter.values] })
        .to eq([[:project_status_code, "=", [Project.status_codes[:at_risk].to_s]]])
    end

    it "is ordered by lft asc" do
      expect(find.orders.map { |order| [order.attribute, order.direction] })
        .to eq([%i[lft asc]])
    end

    it "has the enabled_project_columns columns as selects" do
      expect(find.selects.map(&:attribute))
        .to eq(default_selects)
    end
  end
end
