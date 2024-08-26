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

RSpec.describe ProjectQuery do
  let(:instance) { described_class.new }

  shared_let(:user) { create(:user) }
  shared_let(:admin) { create(:admin) }

  it_behaves_like "acts_as_favorable included" do
    let(:instance) { create(:project_query) }
  end

  context "when persisting" do
    let(:properties) do
      {
        name: "some name",
        user:
      }
    end

    it "takes a name property" do
      instance = described_class.create(**properties)

      expect(described_class.find(instance.id).name)
        .to eql properties[:name]
    end

    it "takes a user property" do
      instance = described_class.create(**properties)

      expect(described_class.find(instance.id).user)
        .to eql properties[:user]
    end

    it "takes filters" do
      instance = described_class.new(**properties)

      instance.where("active", "=", OpenProject::Database::DB_VALUE_TRUE)

      instance.save!

      expect(described_class.find(instance.id).filters.map { |f| { field: f.field, operator: f.operator, values: f.values } })
        .to eql [{ field: :active, operator: "=", values: [OpenProject::Database::DB_VALUE_TRUE] }]
    end

    it "takes sort order" do
      instance = described_class.new(**properties)

      instance.order(id: :desc)

      instance.save!

      expect(described_class.find(instance.id).orders.map { |o| { o.attribute => o.direction } })
        .to eql [{ id: :desc }]
    end

    it "takes selects" do
      instance = described_class.new(**properties)

      instance.select(:name, :public)

      instance.save!

      expect(described_class.find(instance.id).selects.map(&:attribute))
        .to eql %i[name public]
    end
  end

  describe "serialisation" do
    it "doesn't break checking dirty state" do
      instance = build(:project_query)

      instance.where("active", "=", OpenProject::Database::DB_VALUE_TRUE)
      instance.order(id: :desc)
      instance.select(:name, :public)

      instance.clear_changes_information

      instance.filters
      instance.orders
      instance.selects

      expect(instance.changes).to be_empty
    end
  end

  describe ".available_selects" do
    before do
      scope = instance_double(ActiveRecord::Relation)

      allow(ProjectCustomField)
        .to receive(:visible)
              .and_return(scope)

      allow(scope)
        .to receive(:pluck)
              .and_return([23, 42])
    end

    # rubocop:disable Naming/VariableNumber
    context "for non admin user" do
      current_user { user }

      it "lists registered selects" do
        expect(instance.available_selects.map(&:attribute))
          .to match_array(%i[
                            name
                            favored
                            public
                            description
                            hierarchy
                            project_status
                            status_explanation
                            cf_23
                            cf_42
                          ])
      end
    end

    context "for admin user" do
      current_user { admin }

      it "includes admin columns" do
        expect(instance.available_selects.map(&:attribute))
          .to match_array(%i[
                            name
                            favored
                            public
                            description
                            hierarchy
                            project_status
                            status_explanation
                            created_at
                            latest_activity_at
                            required_disk_space
                            cf_23
                            cf_42
                          ])
      end
    end
    # rubocop:enable Naming/VariableNumber
  end

  describe "#valid_subset!" do
    context "with filters" do
      let(:valid_project_ids) do
        project_scope = instance_double(ActiveRecord::Relation)

        allow(Project)
          .to receive(:visible)
                .and_return(project_scope)

        allow(project_scope)
          .to receive(:pluck)
                .with(:id)
                .and_return([1, 2, 3])

        [1, 2, 3]
      end

      context "with them being valid" do
        current_user { admin }

        before do
          instance.where("active", "=", OpenProject::Database::DB_VALUE_TRUE)
          instance.where("member_of", "=", OpenProject::Database::DB_VALUE_TRUE)
          instance.where("created_at", ">t-", ["6"])

          instance.valid_subset!
        end

        it "leaves the values untouched" do
          expect(instance.filters.map { |filter| [filter.field, filter.operator, filter.values] })
            .to eq([[:active, "=", ["t"]], [:member_of, "=", ["t"]], [:created_at, ">t-", ["6"]]])
        end
      end

      context "with one of them being invalid as it is a made up filter name" do
        current_user { user }

        before do
          instance.where("active", "=", OpenProject::Database::DB_VALUE_TRUE)
          instance.where("bogus", ">t-", ["6"])

          instance.valid_subset!
        end

        it "leaves only the valid filters" do
          expect(instance.filters.map { |filter| [filter.field, filter.operator, filter.values] })
            .to eq([[:active, "=", ["t"]]])
        end
      end

      context "with one of them being invalid as it is admin only" do
        current_user { user }

        before do
          instance.where("active", "=", OpenProject::Database::DB_VALUE_TRUE)
          instance.where("created_at", ">t-", ["6"])

          instance.valid_subset!
        end

        it "leaves only the valid filters" do
          expect(instance.filters.map { |filter| [filter.field, filter.operator, filter.values] })
            .to eq([[:active, "=", ["t"]]])
        end
      end

      context "with one of them being invalid as it has one invalid value" do
        current_user { user }

        before do
          instance.where("active", "=", OpenProject::Database::DB_VALUE_TRUE)
          instance.where("parent_id", "=", valid_project_ids.map(&:to_s) + %w[42])

          instance.valid_subset!
        end

        it "keeps the invalid filter but removes the invalid value" do
          expect(instance.filters.map { |filter| [filter.field, filter.operator, filter.values] })
            .to eq([[:active, "=", ["t"]], [:parent_id, "=", valid_project_ids.map(&:to_s)]])
        end
      end

      context "with one of them being invalid as it has only invalid values" do
        current_user { user }

        before do
          instance.where("active", "=", OpenProject::Database::DB_VALUE_TRUE)
          valid_project_ids
          instance.where("parent_id", "=", %w[23 42])

          instance.valid_subset!
        end

        it "keeps only the valid filters" do
          expect(instance.filters.map { |filter| [filter.field, filter.operator, filter.values] })
            .to eq([[:active, "=", ["t"]]])
        end
      end

      context "with one of them being invalid as it has an invalid operator" do
        current_user { user }

        before do
          instance.where("active", "=", OpenProject::Database::DB_VALUE_TRUE)
          instance.where("parent_id", "d=", valid_project_ids.map(&:to_s))

          instance.valid_subset!
        end

        it "keeps only the valid filters" do
          expect(instance.filters.map { |filter| [filter.field, filter.operator, filter.values] })
            .to eq([[:active, "=", ["t"]]])
        end
      end

      context "with all of them being invalid" do
        current_user { user }

        before do
          instance.where("created_at", "=", OpenProject::Database::DB_VALUE_TRUE)
          instance.where("parent_id", "d=", valid_project_ids.map(&:to_s))

          instance.valid_subset!
        end

        it "keeps only the valid filters" do
          expect(instance.filters.map { |filter| [filter.field, filter.operator, filter.values] })
            .to be_empty
        end
      end
    end

    context "with selects" do
      let(:current_user) { user }

      current_user { user }

      before do
        instance.select(*selects)

        instance.valid_subset!
      end

      context "with them being valid" do
        let(:current_user) { admin }
        let(:selects) { %i(name description created_at) }

        it "leaves the values untouched" do
          expect(instance.selects.map(&:attribute))
            .to eq selects
        end
      end

      context "with them being invalid" do
        # No admin, hence no created_at column. CF column does not exist.
        let(:selects) { %i(bogus created_at cf_1) } # rubocop:disable Naming/VariableNumber

        it "removes the values" do
          expect(instance.selects.map(&:attribute))
            .to be_empty
        end
      end

      context "with them being partially invalid" do
        let(:current_user) { admin }
        let(:selects) { %i(bogus name created_at cf_1 description) } # rubocop:disable Naming/VariableNumber

        it "removes only the offending values" do
          expect(instance.selects.map(&:attribute))
            .to eq %i(name created_at description)
        end
      end
    end

    context "with orders" do
      let(:current_user) { user }
      let(:custom_field) { create(:project_custom_field) }

      current_user { user }

      before do
        instance.order(orders)

        instance.valid_subset!
      end

      context "with them being valid" do
        let(:current_user) { admin }
        let(:orders) { { name: :asc, project_status: :desc, "cf_#{custom_field.id}": :desc } }

        it "leaves the values untouched" do
          expect(instance.orders.to_h { [_1.attribute, _1.direction] })
            .to eq orders
        end
      end

      context "with them being invalid" do
        let(:orders) { { bogus: :desc, cf_1: :desc } } # rubocop:disable Naming/VariableNumber

        it "removes the values" do
          expect(instance.orders.to_h { [_1.attribute, _1.direction] })
            .to be_empty
        end
      end

      context "with them being partially invalid" do
        let(:current_user) { admin }
        let(:orders) { { bogus: :desc, name: :desc, cf_0: :desc, "cf_#{custom_field.id}": :desc } } # rubocop:disable Naming/VariableNumber

        it "removes only the offending values" do
          expect(instance.orders.to_h { [_1.attribute, _1.direction] })
            .to eq(name: :desc, "cf_#{custom_field.id}": :desc)
        end
      end
    end
  end

  describe "scopes" do
    shared_let(:public_query) { create(:project_query, user:, public: true) }
    shared_let(:public_query_other_user) { create(:project_query, public: true) }
    shared_let(:private_query) { create(:project_query, user:) }
    shared_let(:private_query_other_user) { create(:project_query) }

    describe ".public_lists" do
      it "returns only public lists" do
        expect(described_class.public_lists).to contain_exactly(public_query, public_query_other_user)
      end
    end

    describe ".private_lists" do
      it "returns only private lists owned by the user" do
        expect(described_class.private_lists(user:)).to contain_exactly(private_query)
      end
    end

    describe ".visible" do
      it "returns public and private queries owned by the user" do
        expect(described_class.visible(user)).to contain_exactly(
          public_query,
          public_query_other_user,
          private_query
        )
      end
    end
  end

  describe "#visible?" do
    let(:public) { false }

    subject { build(:project_query, user: owner, public:) }

    context "when the user is the owner" do
      let(:owner) { user }

      it { is_expected.to be_visible(user) }
    end

    context "when the user is not the owner" do
      let(:owner) { build(:user) }

      context "and the query is public" do
        let(:public) { true }

        it { is_expected.to be_visible(user) }
      end

      context "and the query is private" do
        let(:public) { false }

        it { is_expected.not_to be_visible(user) }
      end

      context "and the query has been shared with the user" do
        before do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project_query(:view_project_query, project_query: subject)
          end
        end

        it { is_expected.to be_visible(user) }
      end
    end
  end

  describe "#editable?" do
    subject { build(:project_query, user: owner, public:) }

    context "when the query is private" do
      let(:public) { false }

      context "and the user is the owner" do
        let(:owner) { user }

        it { is_expected.to be_editable(user) }
      end

      context "and the user is not the owner" do
        let(:owner) { build(:user) }

        it { is_expected.not_to be_editable(user) }

        context "and the query has been shared with the user" do
          before do
            mock_permissions_for(user) do |mock|
              mock.allow_in_project_query(:edit_project_query, project_query: subject)
            end
          end

          it { is_expected.to be_editable(user) }
        end
      end
    end

    context "when the query is public" do
      let(:public) { true }

      context "and the user is the owner" do
        let(:owner) { user }

        it { is_expected.not_to be_editable(user) }

        context "and the user has the global permission" do
          before do
            mock_permissions_for(user) do |mock|
              mock.allow_globally(:manage_public_project_queries)
            end
          end

          it { is_expected.to be_editable(user) }
        end
      end

      context "and the user is not the owner" do
        let(:owner) { build(:user) }

        it { is_expected.not_to be_editable(user) }

        context "and the user has the global permission" do
          before do
            mock_permissions_for(user) do |mock|
              mock.allow_globally(:manage_public_project_queries)
            end
          end

          it { is_expected.to be_editable(user) }
        end

        context "and the query has been shared with the user" do
          before do
            mock_permissions_for(user) do |mock|
              mock.allow_in_project_query(:edit_project_query, project_query: subject)
            end
          end

          it { is_expected.to be_editable(user) }
        end
      end
    end
  end
end
