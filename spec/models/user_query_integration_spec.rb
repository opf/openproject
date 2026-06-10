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

# Integration coverage for UserQuery with real users, real custom fields and
# real persistence. Unit-level expectations live in user_query_spec.rb;
# this spec exercises the full filter→SQL→ActiveRecord round trip.
RSpec.describe UserQuery, "integration" do
  shared_let(:job_title_cf) do
    create(:user_custom_field, :list,
           name: "Job title",
           possible_values: ["Developer", "Designer", "Project Manager", "Product Manager"])
  end
  shared_let(:nickname_cf) do
    create(:user_custom_field, :string, name: "Nickname")
  end
  shared_let(:birthday_cf) do
    create(:user_custom_field, :date, name: "Birthday")
  end

  shared_let(:developer_option) { job_title_cf.custom_options.find_by(value: "Developer") }
  shared_let(:designer_option) { job_title_cf.custom_options.find_by(value: "Designer") }
  shared_let(:pm_option) { job_title_cf.custom_options.find_by(value: "Project Manager") }

  # Alice is the logged-in user across most examples; she needs view_all_principals
  # so the existing filter/order expectations enumerate every seeded user.
  # Visibility behaviour is exercised separately in the `describe "visibility"` block.
  shared_let(:alice) { create(:user, firstname: "Alice", lastname: "Anders", global_permissions: %i[view_all_principals]) }
  shared_let(:bob) { create(:user, firstname: "Bob", lastname: "Bauer") }
  shared_let(:carol) { create(:user, firstname: "Carol", lastname: "Cohen") }
  shared_let(:dave) { create(:user, firstname: "Dave", lastname: "Doe") }
  shared_let(:locked_eve) { create(:user, firstname: "Eve", lastname: "Eriksson", status: :locked) }

  before_all do
    [[alice,      developer_option, "ace",        "1990-04-12"],
     [bob,        developer_option, "bobster",    "1985-09-23"],
     [carol,      designer_option,  "carol-bear", "1995-02-14"],
     [dave,       pm_option,        nil,          "2001-07-08"],
     [locked_eve, developer_option, "evil-eve",   "1980-11-30"]].each do |user, option, nickname, birthday|
      values = { job_title_cf.id => option.id, birthday_cf.id => birthday }
      values[nickname_cf.id] = nickname if nickname
      user.custom_field_values = values
      user.save!(validate: false)
    end
  end

  before { login_as(alice) }

  let(:query) { described_class.new(name: "Users") }

  describe "filtering by a list custom field" do
    it "returns only users whose CF value matches the selected option" do
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])

      expect(query.results).to contain_exactly(alice, bob, locked_eve)
    end

    it "supports the negated operator (excludes the matching option, includes users with no value)" do
      query.where(job_title_cf.column_name, "!", [developer_option.id.to_s])

      expect(query.results).to contain_exactly(carol, dave)
    end

    it "supports 'all and non-blank' to find users with any value set" do
      query.where(job_title_cf.column_name, "*", [])

      expect(query.results).to contain_exactly(alice, bob, carol, dave, locked_eve)
    end

    it "supports 'none or blank' to find users with no value set" do
      # All seeded users have a job title, so a fresh user with no CF data should be the only match.
      blank_user = create(:user, firstname: "Frank", lastname: "Frost")

      query.where(job_title_cf.column_name, "!*", [])

      expect(query.results).to contain_exactly(blank_user)
    end
  end

  describe "filtering by a string custom field" do
    it "supports the contains (~) operator" do
      query.where(nickname_cf.column_name, "~", ["bear"])

      expect(query.results).to contain_exactly(carol)
    end
  end

  describe "filtering by a date custom field" do
    # The date filter uses "<>d" (between dates). Leaving the upper bound empty
    # gives "on or after <date>" semantics — i.e. the "greater than or equal" case.
    it "returns users with a birthday on or after a cutoff date" do
      query.where(birthday_cf.column_name, "<>d", ["1990-01-01", ""])

      expect(query.results).to contain_exactly(alice, carol, dave)
    end

    it "returns users with a birthday on or before a cutoff date" do
      query.where(birthday_cf.column_name, "<>d", ["", "1989-12-31"])

      expect(query.results).to contain_exactly(bob, locked_eve)
    end

    it "returns users with a birthday inside a closed interval" do
      query.where(birthday_cf.column_name, "<>d", ["1985-01-01", "1995-12-31"])

      expect(query.results).to contain_exactly(alice, bob, carol)
    end
  end

  describe "combining a CF filter with built-in filters" do
    it "applies status and CF filters with AND semantics" do
      query.where("status", "=", ["active"])
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])

      expect(query.results).to contain_exactly(alice, bob)
    end

    it "applies a name filter together with a CF filter" do
      query.where("name", "~", ["alice"])
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])

      expect(query.results).to contain_exactly(alice)
    end
  end

  describe "ordering does not interfere with CF filtering" do
    it "returns matching users in the requested order" do
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])
      query.order(id: :asc)

      expect(query.results.to_a).to eq([alice, bob, locked_eve].sort_by(&:id))
    end
  end

  describe "ordering by a custom field" do
    it "sorts users by a string CF value asc, with users without a value first" do
      query.order(nickname_cf.column_name => :asc)

      ordered = query.results.to_a

      # dave has no nickname → NULLS FIRST on asc
      expect(ordered.first).to eq(dave)
      # remaining users sorted by their nickname value: ace, bobster, carol-bear, evil-eve
      expect(ordered.drop(1)).to eq([alice, bob, carol, locked_eve])
    end

    it "sorts users by a list CF value (option position)" do
      query.order(job_title_cf.column_name => :asc)

      grouped = query.results.to_a.group_by { |u| u.custom_value_for(job_title_cf)&.value&.to_i }
      developer_users = grouped[developer_option.id]
      designer_users = grouped[designer_option.id]
      pm_users = grouped[pm_option.id]

      expect(developer_users).to contain_exactly(alice, bob, locked_eve)
      expect(designer_users).to eq([carol])
      expect(pm_users).to eq([dave])

      # CustomOption position drives the order — the seeded `possible_values` order is
      # Developer, Designer, Project Manager, Product Manager.
      first_titles = query.results.to_a.map { |u| u.custom_value_for(job_title_cf)&.value&.to_i }
      expect(first_titles.compact).to eq(first_titles.compact.sort_by do |id|
        [developer_option.id, designer_option.id, pm_option.id].index(id) || Float::INFINITY
      end)
    end

    it "sorts users by a date CF asc (oldest birthday first)" do
      query.order(birthday_cf.column_name => :asc)

      # All five seeded users have a birthday set, so no NULLS-FIRST padding.
      expect(query.results.to_a).to eq([locked_eve, bob, alice, carol, dave])
    end

    it "sorts users by a date CF desc (newest birthday first)" do
      query.order(birthday_cf.column_name => :desc)

      expect(query.results.to_a).to eq([dave, carol, alice, bob, locked_eve])
    end

    it "combines a date CF filter with a date CF order" do
      query.where(birthday_cf.column_name, "<>d", ["1990-01-01", ""])
      query.order(birthday_cf.column_name => :asc)

      expect(query.results.to_a).to eq([alice, carol, dave])
    end

    it "rejects ordering by a text CF (excluded from sortable formats)" do
      text_cf = create(:user_custom_field, :text, name: "Bio")

      query.order(text_cf.column_name => :asc)

      expect(query).not_to be_valid
    end
  end

  describe "selecting a custom field column" do
    it "exposes a select for every visible UserCustomField" do
      available = Queries::Users::Selects::CustomField.all_available.map(&:attribute)

      expect(available).to include(:"cf_#{job_title_cf.id}", :"cf_#{nickname_cf.id}")
    end

    it "constructs a valid select pointing at the right CustomField" do
      select = Queries::Users::Selects::CustomField.new(:"cf_#{job_title_cf.id}")

      expect(select).to be_available
      expect(select.custom_field).to eq(job_title_cf)
      expect(select.caption).to eq(job_title_cf.name)
    end
  end

  describe "visibility" do
    # Override the outer admin login so each context can pin down its own viewer.
    let(:viewer) { create(:user, firstname: "Viewer", lastname: "Visible") }

    before { login_as(viewer) }

    context "when the current user is an admin" do
      let(:viewer) { create(:admin, firstname: "Viewer", lastname: "Admin") }

      it "returns every active user" do
        expect(query.results).to include(alice, bob, carol, dave, locked_eve, viewer)
      end
    end

    context "when the current user has the :view_all_principals global permission" do
      let(:viewer) do
        create(:user, firstname: "Viewer", lastname: "Global",
                      global_permissions: %i[view_all_principals])
      end

      it "returns every active user" do
        expect(query.results).to include(alice, bob, carol, dave, locked_eve, viewer)
      end
    end

    context "when the current user has no view permission and no shared membership" do
      it "only sees themselves" do
        expect(query.results).to contain_exactly(viewer)
      end

      it "sees other users that share a project membership" do
        role = create(:project_role)
        project = create(:project)
        create(:member, principal: viewer, project: project, roles: [role])
        create(:member, principal: alice, project: project, roles: [role])

        expect(query.results).to contain_exactly(viewer, alice)
      end

      it "sees other users that share a group membership" do
        create(:group, members: [viewer, alice])

        expect(query.results).to contain_exactly(viewer, alice)
      end

      it "does not see users that share neither a project nor a group" do
        expect(query.results).not_to include(bob, carol, dave, locked_eve)
      end
    end
  end

  describe "PersistedQuery round-trip" do
    it "persists and re-runs a UserQuery with a CF filter" do
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])
      query.where("status", "=", ["active"])
      query.order(name: :asc)
      query.save!

      reloaded = described_class.find(query.id)

      expect(reloaded.filters.size).to eq(2)
      cf_filter = reloaded.filters.detect { |f| f.is_a?(Queries::Filters::Shared::CustomFields::ListOptional) }
      expect(cf_filter).not_to be_nil
      expect(cf_filter.custom_field).to eq(job_title_cf)
      expect(cf_filter.values).to eq([developer_option.id.to_s])
      expect(reloaded.orders.first).to be_a(Queries::Users::Orders::NameOrder)

      expect(reloaded.results).to contain_exactly(alice, bob)
    end

    it "persists and re-runs a UserQuery with a CF order and a CF select" do
      query.where("status", "=", ["active"])
      query.order(job_title_cf.column_name => :asc)
      query.select(:"cf_#{job_title_cf.id}")
      query.save!

      reloaded = described_class.find(query.id)

      expect(reloaded.orders.first).to be_a(Queries::Users::Orders::CustomFieldOrder)
      expect(reloaded.orders.first.custom_field).to eq(job_title_cf)
      expect(reloaded.selects.first).to be_a(Queries::Users::Selects::CustomField)
      expect(reloaded.selects.first.custom_field).to eq(job_title_cf)

      # Result is still scoped by the persisted filter and ordered by the CF.
      expect(reloaded.results.to_a).to include(alice, bob, carol, dave)
    end

    it "stores the CF filter as the cf_<id> attribute hash in the database" do
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])
      query.save!

      raw_filters = PersistedQuery.connection.select_value(
        "SELECT filters FROM persisted_queries WHERE id = #{query.id}"
      )
      raw_filters = JSON.parse(raw_filters) if raw_filters.is_a?(String)

      expect(raw_filters).to eq([{
                                  "attribute" => job_title_cf.column_name,
                                  "operator" => "=",
                                  "values" => [developer_option.id.to_s]
                                }])
    end

    it "falls back to a NotExistingFilter when the referenced CF has been deleted" do
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])
      query.save!

      job_title_cf.destroy!
      # The shared CF filter caches `UserCustomField.all` in RequestStore for the
      # life of the request; clear it so the deserializer sees the deletion.
      RequestStore.clear!

      reloaded = described_class.find(query.id)
      expect(reloaded.filters.first).to be_a(Queries::Filters::NotExistingFilter)
      expect(reloaded).not_to be_valid
    end
  end
end
