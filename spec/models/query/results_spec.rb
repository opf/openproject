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

RSpec.describe Query::Results do
  let(:query) do
    build(:query,
          show_hierarchies: false)
  end
  let(:query_results) do
    described_class.new query
  end
  let(:project1) { create(:project) }
  let(:role_pm) do
    create(:project_role,
           permissions: %i(
             view_work_packages
             edit_work_packages
             create_work_packages
             delete_work_packages
           ))
  end
  let(:role_dev) do
    create(:project_role,
           permissions: [:view_work_packages])
  end
  let(:user1) do
    create(:user,
           firstname: "user",
           lastname: "1",
           member_with_roles: { project1 => [role_dev, role_pm] })
  end
  let(:wp_p1) do
    (1..3).map do
      create(:work_package,
             project: project1,
             assigned_to_id: user1.id)
    end
  end

  describe "#work_package_count_by_group" do
    let(:query) do
      build(:query,
            show_hierarchies: false,
            group_by:,
            project: project1)
    end
    let(:type1) do
      create(:type)
    end
    let(:type2) do
      create(:type)
    end
    let(:work_package1) do
      create(:work_package,
             type: type1,
             project: project1)
    end
    let(:work_package2) do
      create(:work_package,
             type: type2,
             project: project1)
    end

    context "when grouping by responsible" do
      let(:group_by) { "responsible" }

      it "produces a valid SQL statement" do
        expect { query_results.work_package_count_by_group }.not_to raise_error
      end
    end

    context "when grouping and filtering by text" do
      let(:group_by) { "responsible" }

      before do
        query.add_filter("search", "**", ["asdf"])
      end

      it "produces a valid SQL statement (Regression #29598)" do
        expect { query_results.work_package_count_by_group }.not_to raise_error
      end
    end

    context "when grouping by assigned_to" do
      let(:group_by) { "assigned_to" }

      before do
        work_package1
        work_package2.update_column(:assigned_to_id, user1.id)

        login_as(user1)
      end

      it "returns a hash of counts by value" do
        expect(query_results.work_package_count_by_group).to eql(nil => 1, user1 => 1)
      end
    end

    context "when grouping by assigned_to with only a nil group" do
      let(:group_by) { "assigned_to" }

      before do
        work_package1

        login_as(user1)
      end

      it "returns a hash of counts by value" do
        expect(query_results.work_package_count_by_group).to eql(nil => 1)
      end
    end

    context "when grouping by type" do
      let(:group_by) { "type" }

      before do
        work_package1
        work_package2

        login_as(user1)
      end

      it "returns the groups sorted by type`s position" do
        type1.update_column(:position, 1)
        type2.update_column(:position, 2)

        result = query_results.work_package_count_by_group

        expect(result.length)
          .to be 2

        expect(result.keys.map(&:id))
          .to eql [type1.id, type2.id]

        type1.update_column(:position, 2)
        type2.update_column(:position, 1)

        new_results = described_class.new(query)

        result = new_results.work_package_count_by_group

        expect(result.length)
          .to be 2

        expect(result.keys.map(&:id))
          .to eql [type2.id, type1.id]
      end
    end

    context "when grouping by list custom field and filtering for it at the same time" do
      let!(:custom_field) do
        create(:list_wp_custom_field,
               is_for_all: true,
               is_filter: true,
               multi_value: true,
               types: [work_package1.type, work_package2.type])
      end
      let(:first_value) do
        custom_field.custom_options.first
      end
      let(:last_value) do
        custom_field.custom_options.last
      end
      let(:group_by) { custom_field.column_name }

      before do
        login_as(user1)

        work_package1.send(custom_field.attribute_setter, first_value)
        work_package1.save!
        work_package2.send(custom_field.attribute_setter, [first_value,
                                                           last_value])
        work_package2.save!
      end

      it "yields no error but rather returns the result" do
        expect { query_results.work_package_count_by_group }.not_to raise_error

        group_count = query_results.work_package_count_by_group
        expected_groups = [[first_value], [first_value, last_value]]

        group_count.each do |key, count|
          expect(count).to be 1
          expect(expected_groups).to(be_any { |group| group & key == key & group })
        end
      end
    end

    context "when grouping by int custom field" do
      let!(:custom_field) do
        create(:integer_wp_custom_field,
               is_for_all: true,
               is_filter: true,
               projects: [project1],
               types: [wp_p1[0].type])
      end

      let(:group_by) { custom_field.column_name }

      before do
        login_as(user1)

        wp_p1[0].update_attribute(custom_field.attribute_name, 42)
        wp_p1[0].save
        wp_p1[1].update_attribute(custom_field.attribute_name, 42)
        wp_p1[1].save
      end

      it "returns a hash of counts by value" do
        expect(query_results.work_package_count_by_group).to eql(42 => 2, nil => 1)
      end
    end

    context "when grouping by user custom field" do
      let!(:custom_field) do
        create(:user_wp_custom_field, is_for_all: true, is_filter: true)
      end

      let(:group_by) { custom_field.column_name }

      before do
        login_as(user1)

        wp_p1[0].type.custom_fields << custom_field
        project1.work_package_custom_fields << custom_field
      end

      it "returns nil as user custom fields are not groupable" do
        expect(query_results.work_package_count_by_group).to be_nil
      end
    end

    context "when grouping by bool custom field" do
      let!(:custom_field) do
        create(:boolean_wp_custom_field,
               is_for_all: true,
               is_filter: true,
               projects: [project1],
               types: [wp_p1[0].type])
      end

      let(:group_by) { custom_field.column_name }

      before do
        login_as(user1)

        wp_p1[0].update_attribute(custom_field.attribute_name, true)
        wp_p1[0].save
        wp_p1[1].update_attribute(custom_field.attribute_name, true)
        wp_p1[1].save
      end

      it "returns a hash of counts by value" do
        expect(query_results.work_package_count_by_group).to eql(true => 2, nil => 1)
      end
    end

    context "when grouping by date custom field" do
      let!(:custom_field) do
        create(:date_wp_custom_field,
               is_for_all: true,
               is_filter: true,
               projects: [project1],
               types: [wp_p1[0].type])
      end

      let(:group_by) { custom_field.column_name }

      before do
        login_as(user1)

        wp_p1[0].update_attribute(custom_field.attribute_name, Time.zone.today)
        wp_p1[0].save
        wp_p1[1].update_attribute(custom_field.attribute_name, Time.zone.today)
        wp_p1[1].save
      end

      it "returns a hash of counts by value" do
        expect(query_results.work_package_count_by_group).to eql(Time.zone.today => 2, nil => 1)
      end
    end
  end

  describe "filtering" do
    let!(:project1) { create(:project) }
    let!(:project2) { create(:project) }
    let!(:member) do
      create(:member,
             project: project2,
             principal: user1,
             roles: [role_pm])
    end
    let!(:user2) do
      create(:user,
             firstname: "user",
             lastname: "2",
             member_with_roles: { project2 => role_dev })
    end

    let!(:wp_p2) do
      create(:work_package,
             project: project2,
             assigned_to_id: user2.id)
    end
    let!(:wp2_p2) do
      create(:work_package,
             project: project2,
             assigned_to_id: user1.id)
    end

    before do
      wp_p1
    end

    context "when filtering for assigned_to_role" do
      before do
        allow(User).to receive(:current).and_return(user2)
        allow(project2.descendants).to receive(:active).and_return([])

        query.add_filter("assigned_to_role", "=", [role_dev.id.to_s])
      end

      context "when a project is set" do
        let(:query) { build(:query, project: project2) }

        it "displays only wp for selected project and selected role" do
          expect(query_results.work_packages).to contain_exactly(wp_p2)
        end
      end

      context "when no project is set" do
        let(:query) { build(:query, project: nil) }

        it "displays all wp from projects where User.current has access" do
          expect(query_results.work_packages).to contain_exactly(wp_p2, wp2_p2)
        end
      end
    end

    # this tests some unfortunate combination of filters where wrong
    # sql statements where produced.
    context "with a custom field being returned and paginating" do
      let(:group_by) { nil }
      let(:query) do
        build_stubbed(:query,
                      show_hierarchies: false,
                      group_by:,
                      project: project2)
      end

      let!(:custom_field) { create(:work_package_custom_field, is_for_all: true) }

      before do
        allow(User).to receive(:current).and_return(user2)

        # reload in order to have the custom field as an available
        # custom field
        query.project = Project.find(query.project.id)
      end

      context "when grouping by assignees" do
        before do
          query.column_names = [:assigned_to, custom_field.column_name.to_sym]
          query.group_by = "assigned_to"
        end

        it "returns all work packages of project 2" do
          work_packages = query
                          .results
                          .work_packages
                          .page(1)
                          .per_page(10)

          expect(work_packages).to contain_exactly(wp_p2, wp2_p2)
        end
      end

      context "when grouping by responsibles" do
        let(:group_by) { "responsible" }

        before do
          query.column_names = [:responsible, custom_field.column_name.to_sym]
        end

        it "returns all work packages of project 2" do
          work_packages = query
                          .results
                          .work_packages
                          .page(1)
                          .per_page(10)

          expect(work_packages).to contain_exactly(wp_p2, wp2_p2)
        end
      end
    end

    context "when grouping by responsible" do
      let(:query) do
        build(:query,
              show_hierarchies: false,
              group_by:,
              project: project1)
      end
      let(:group_by) { "responsible" }

      before do
        allow(User).to receive(:current).and_return(user1)

        wp_p1[0].update_attribute(:responsible, user1)
        wp_p1[1].update_attribute(:responsible, user2)
      end

      it "outputs the work package count in the schema { <User> => count }" do
        expect(query_results.work_package_count_by_group)
          .to eql(user1 => 1, user2 => 1, nil => 1)
      end
    end

    context "when filtering by precedes and ordering by id" do
      let(:query) do
        build(:query,
              project: project1)
      end

      before do
        login_as(user1)

        create(:follows_relation, to: wp_p1[1], from: wp_p1[0])

        query.add_filter("precedes", "=", [wp_p1[0].id.to_s])

        query.sort_criteria = [["id", "asc"]]

        # Reload is necessary as it fixes the lft/rgt columns of nested set
        # that on some runs end up being the same as project2 (reason unknown),
        # whereby the filter ends up with an invalid value since project2 gets loaded when
        # executing project1.self_and_descendants where the wp_p1[0] is not in.
        project1.reload
      end

      it "returns the work packages preceding the filtered for work package" do
        expect(query.results.work_packages)
          .to match_array(wp_p1[1])
      end
    end
  end

  context "when filtering by bool cf" do
    let(:query) do
      build_stubbed(:query,
                    show_hierarchies: false,
                    group_by:,
                    sort_criteria: sort_by,
                    project: project1,
                    column_names: columns)
    end

    let(:bool_cf) do
      create(:boolean_wp_custom_field,
             is_filter: true,
             projects: [work_package1.project],
             types: [work_package1.type])
    end
    let(:custom_value) do
      create(:custom_value,
             custom_field: bool_cf,
             customized: work_package1,
             value:)
    end
    let(:value) { "t" }
    let(:filter_value) { "t" }
    let(:work_package1) { create(:work_package, project: project1) }
    let(:work_package2) { create(:work_package, project: project1, id: 2) }
    let(:work_package3) { create(:work_package, project: project1, id: 3) }
    let(:sort_by) { [%w[id asc]] }
    let(:columns) { %i(id subject) }
    let(:group_by) { "" }

    before do
      allow(User).to receive(:current).and_return(user1)

      custom_value

      query.add_filter(bool_cf.column_name.to_sym, "=", [filter_value])
    end

    shared_examples_for "is empty" do
      it "is empty" do
        expect(query.results.work_packages)
          .to be_empty
      end
    end

    shared_examples_for "returns the wp" do
      it "returns the wp" do
        expect(query.results.work_packages)
          .to match_array(work_package1)
      end
    end

    context "with the wp having true for the cf" do
      context "and filtering for true" do
        it_behaves_like "returns the wp"
      end

      context "and filtering for false" do
        let(:filter_value) { "f" }

        it_behaves_like "is empty"
      end
    end

    context "with the wp having false for the cf" do
      let(:value) { "f" }

      context "and filtering for true" do
        it_behaves_like "is empty"
      end

      context "and filtering for false" do
        let(:filter_value) { "f" }

        it_behaves_like "returns the wp"
      end
    end

    context "with the wp having no value for the cf" do
      let(:custom_value) { nil }

      context "and filtering for true" do
        it_behaves_like "is empty"
      end

      context "and filtering for false" do
        let(:filter_value) { "f" }

        it_behaves_like "returns the wp"

        context "and the cf not being active for the type" do
          let(:bool_cf) do
            create(:boolean_wp_custom_field,
                   is_filter: true,
                   types: [work_package1.type])
          end

          it_behaves_like "is empty"
        end

        context "and the cf not being active in the project and the cf being for all" do
          let(:bool_cf) do
            create(:boolean_wp_custom_field,
                   is_filter: true,
                   is_for_all: true,
                   projects: [work_package1.project])
          end

          it_behaves_like "is empty"
        end
      end
    end
  end
end
