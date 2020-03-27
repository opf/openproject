#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.join(File.dirname(__FILE__), '..', '..', 'support', 'custom_field_filter')

describe CostQuery, type: :model, reporting_query_helper: true do
  minimal_query

  let!(:project) { FactoryBot.create(:project_with_types) }
  let!(:user) { FactoryBot.create(:user, member_in_project: project) }

  def create_work_package_with_entry(entry_type, work_package_params={}, entry_params = {})
    work_package_params = {project: project}.merge!(work_package_params)
    work_package = FactoryBot.create(:work_package, work_package_params)
    entry_params = {work_package: work_package,
                    project: work_package_params[:project],
                    user: user}.merge!(entry_params)
    FactoryBot.create(entry_type, entry_params)
    work_package
  end

  describe CostQuery::Filter do
    def create_work_package_with_time_entry(work_package_params={}, entry_params = {})
      create_work_package_with_entry(:time_entry, work_package_params, entry_params)
    end

    it "shows all entries when no filter is applied" do
      expect(@query.result.count).to eq(Entry.count)
    end

    it "always sets cost_type" do
      @query.result.each do |result|
        expect(result["cost_type"]).not_to be_nil
      end
    end

    it "sets activity_id to -1 for cost entries" do
      @query.result.each do |result|
        expect(result["activity_id"].to_i).to eq(-1) if result["type"] != "TimeEntry"
      end
    end

    # Test Work Package attributes that are included in of the result set

    [
      [CostQuery::Filter::ProjectId,        'project',    "project_id",      2],
      [CostQuery::Filter::UserId,           'user',       "user_id",         2],
      [CostQuery::Filter::CostTypeId,       'cost_type',  "cost_type_id",    1],
      [CostQuery::Filter::WorkPackageId,    'work_package',      "work_package_id", 2],
      [CostQuery::Filter::ActivityId, 'activity',   "activity_id",     1],
    ].each do |filter, object_name, field, expected_count|
      describe filter do
        let!(:non_matching_entry) { FactoryBot.create(:cost_entry) }
        let!(:object) { send(object_name) }
        let!(:author) { FactoryBot.create(:user, member_in_project: project) }
        let!(:work_package) { FactoryBot.create(:work_package, project: project,
                                                 author: author) }
        let!(:cost_type) { FactoryBot.create(:cost_type) }
        let!(:cost_entry) { FactoryBot.create(:cost_entry, work_package: work_package,
                                               user: user,
                                               project: project,
                                               cost_type: cost_type) }
        let!(:activity) { FactoryBot.create(:time_entry_activity) }
        let!(:time_entry) { FactoryBot.create(:time_entry, work_package: work_package,
                                               user: user,
                                               project: project,
                                               activity: activity) }

        it "should only return entries from the given #{filter.to_s}" do
          @query.filter field, value: object.id
          @query.result.each do |result|
            expect(result[field].to_s).to eq(object.id.to_s)
          end
        end

        it "should allow chaining the same filter" do
          @query.filter field, value: object.id
          @query.filter field, value: object.id
          @query.result.each do |result|
            expect(result[field].to_s).to eq(object.id.to_s)
          end
        end

        it "should return no results for excluding filters" do
          @query.filter field, value: object.id
          @query.filter field, value: object.id + 1
          expect(@query.result.count).to eq(0)
        end

        it "should compute the correct number of results" do
          @query.filter field, value: object.id
          expect(@query.result.count).to eq(expected_count)
        end
      end
    end

    # Test author attribute separately as it is not included in the result set

    describe CostQuery::Filter::AuthorId do
      let!(:non_matching_entry) { FactoryBot.create(:cost_entry) }
      let!(:author) { FactoryBot.create(:user, member_in_project: project) }
      let!(:work_package) { FactoryBot.create(:work_package, project: project,
                                               author: author) }
      let!(:cost_type) { FactoryBot.create(:cost_type) }
      let!(:cost_entry) { FactoryBot.create(:cost_entry, work_package: work_package,
                                             user: user,
                                             project: project,
                                             cost_type: cost_type) }
      let!(:activity) { FactoryBot.create(:time_entry_activity) }
      let!(:time_entry) { FactoryBot.create(:time_entry, work_package: work_package,
                                             user: user,
                                             project: project,
                                             activity: activity) }

      it "should only return entries from the given CostQuery::Filter::AuthorId" do
        @query.filter 'author_id', value: author.id
        @query.result.each do |result|
          work_package_id = result["work_package_id"]
          expect(WorkPackage.find(work_package_id).author.id).to eq(author.id)
        end
      end

      it "should allow chaining the same filter" do
        @query.filter 'author_id', value: author.id
        @query.filter 'author_id', value: author.id
        @query.result.each do |result|
          work_package_id = result["work_package_id"]
          expect(WorkPackage.find(work_package_id).author.id).to eq(author.id)
        end
      end

      it "should return no results for excluding filters" do
        @query.filter 'author_id', value: author.id
        @query.filter 'author_id', value: author.id + 1
        expect(@query.result.count).to eq(0)
      end

      it "should compute the correct number of results" do
        @query.filter 'author_id', value: author.id
        expect(@query.result.count).to eq(2)
      end
    end

    it "filters spent_on" do
      @query.filter :spent_on, operator: 'w'
      expect(@query.result.count).to eq(Entry.all.select { |e| e.spent_on.cweek == TimeEntry.all.first.spent_on.cweek }.count)
    end

    it "filters created_on" do
      @query.filter :created_on, operator: 't'
      # we assume that some of our fixtures set created_on to Time.now
      expect(@query.result.count).to eq(Entry.all.select { |e| e.created_on.to_date == Date.today }.count)
    end

    it "filters updated_on" do
      @query.filter :updated_on, value: Date.today.years_ago(20), operator: '>d'
      # we assume that our were updated in the last 20 years
      expect(@query.result.count).to eq(Entry.all.select { |e| e.updated_on.to_date > Date.today.years_ago(20) }.count)
    end

    it "filters user_id" do
      old_user = User.current
      # create non-matching entry
      anonymous = FactoryBot.create(:anonymous)
      create_work_package_with_time_entry({}, {user: anonymous})
      # create matching entry
      create_work_package_with_time_entry()
      @query.filter :user_id, value: user.id, operator: '='
      expect(@query.result.count).to eq(1)
    end

    describe "work_package-based filters" do
      def create_work_packages_and_time_entries(entry_count, work_package_params={}, entry_params={})
        entry_count.times do
          create_work_package_with_entry(:cost_entry, work_package_params, entry_params)
        end
      end

      def create_matching_object_with_time_entries(factory, work_package_field, entry_count)
        object = FactoryBot.create(factory)
        create_work_packages_and_time_entries(entry_count, {work_package_field => object})
        object
      end

      it "filters overridden_costs" do
        @query.filter :overridden_costs, operator: 'y'
        expect(@query.result.count).to eq(Entry.all.select { |e| not e.overridden_costs.nil? }.count)
      end

      it "filters status" do
        matching_status = FactoryBot.create(:status, is_closed: true)
        create_work_packages_and_time_entries(3, status: matching_status)
        @query.filter :status_id, operator: 'c'
        expect(@query.result.count).to eq(3)
      end

      it "filters types" do
        matching_type = project.types.first
        create_work_packages_and_time_entries(3, type: matching_type)
        @query.filter :type_id, operator: '=', value: matching_type.id
        expect(@query.result.count).to eq(3)
      end

      it "filters work_package authors" do
        matching_author = create_matching_object_with_time_entries(:user, :author, 3)
        @query.filter :author_id, operator: '=', value: matching_author.id
        expect(@query.result.count).to eq(3)
      end

      it "filters priority" do
        matching_priority = create_matching_object_with_time_entries(:priority, :priority, 3)
        @query.filter :priority_id, operator: '=', value: matching_priority.id
        expect(@query.result.count).to eq(3)
      end

      it "filters assigned to" do
        matching_user = create_matching_object_with_time_entries(:user, :assigned_to, 3)
        @query.filter :assigned_to_id, operator: '=', value: matching_user.id
        expect(@query.result.count).to eq(3)
      end

      it "filters category" do
        category = FactoryBot.create(:category, project: project)
        create_work_packages_and_time_entries(3, category: category)
        @query.filter :category_id, operator: '=', value: category.id
        expect(@query.result.count).to eq(3)
      end

      it "filters target version" do
        matching_version = FactoryBot.create(:version, project: project)
        create_work_packages_and_time_entries(3, version: matching_version)

        @query.filter :version_id, operator: '=', value: matching_version.id
        expect(@query.result.count).to eq(3)
      end

      it "filters subject" do
        matching_work_package = create_work_package_with_time_entry(subject: 'matching subject')
        @query.filter :subject, operator: '=', value: 'matching subject'
        expect(@query.result.count).to eq(1)
      end

      it "filters start" do
        start_date = Date.new(2013, 1, 1)
        matching_work_package = create_work_package_with_time_entry(start_date: start_date)
        @query.filter :start_date, operator: '=d', value: start_date
        expect(@query.result.count).to eq(1)
        #Entry.all.select { |e| e.work_package.start_date == WorkPackage.all(:order => "id ASC").first.start_date }.count
      end

      it "filters due date" do
        due_date = Date.new(2013, 1, 1)
        matching_work_package = create_work_package_with_time_entry(due_date: due_date)
        @query.filter :due_date, operator: '=d', value: due_date
        expect(@query.result.count).to eq(1)
        #Entry.all.select { |e| e.work_package.due_date == WorkPackage.all(:order => "id ASC").first.due_date }.count
      end

      it "raises an error if operator is not supported" do
        expect { @query.filter :spent_on, operator: 'c' }.to raise_error(ArgumentError)
      end
    end

    #filter for specific objects, which can't be null
    [
      CostQuery::Filter::UserId,
      CostQuery::Filter::CostTypeId,
      CostQuery::Filter::AuthorId,
      CostQuery::Filter::ActivityId,
      CostQuery::Filter::PriorityId,
      CostQuery::Filter::TypeId
    ].each do |filter|
      it "should only allow default operators for #{filter}" do
        expect(filter.new.available_operators.uniq.sort).to eq(CostQuery::Operator.default_operators.uniq.sort)
      end
    end

    #filter for specific objects, which might be null
    [
      CostQuery::Filter::AssignedToId,
      CostQuery::Filter::CategoryId,
      CostQuery::Filter::VersionId
    ].each do |filter|
      it "should only allow default+null operators for #{filter}" do
        expect(filter.new.available_operators.uniq.sort).to eq((CostQuery::Operator.default_operators + CostQuery::Operator.null_operators).sort)
      end
    end

    #filter for specific objects, which can only have the default operator
    [
      CostQuery::Filter::WorkPackageId
    ].each do |filter|
      it "should only allow default operators for #{filter}" do
        expect(filter.new.available_operators.uniq).to match_array([CostQuery::Operator.default_operator])
      end
    end

    #filter for time/date
    [
      CostQuery::Filter::CreatedOn,
      CostQuery::Filter::UpdatedOn,
      CostQuery::Filter::SpentOn,
      CostQuery::Filter::StartDate,
      CostQuery::Filter::DueDate
    ].each do |filter|
      it "should only allow time operators for #{filter}" do
        expect(filter.new.available_operators.uniq.sort).to eq(CostQuery::Operator.time_operators.sort)
      end
    end

    describe CostQuery::Filter::CustomFieldEntries do
      let!(:custom_field) do
        cf = FactoryBot.create(:work_package_custom_field,
                                name: 'My custom field')
        clear_cache
        cf
      end

      let(:custom_field2) do
        FactoryBot.build(:work_package_custom_field, name: 'Database',
                                                      field_format: "list",
                                                      possible_values: ['value'])
      end

      after(:all) do
        clear_cache
      end

      def clear_cache
        CostQuery::Cache.reset!
        CostQuery::Filter::CustomFieldEntries.all
      end

      def delete_work_package_custom_field(cf)
        cf.destroy
        clear_cache
      end

      def update_work_package_custom_field(name, options)
        fld = WorkPackageCustomField.find_by(name: name)
        options.each_pair {|k, v| fld.send(:"#{k}=", v) }
        fld.save!
        clear_cache
      end

      include OpenProject::Reporting::SpecHelper::CustomFieldFilterHelper

      it "should create classes for custom fields that get added after starting the server" do
        custom_field
        expect { filter_class_name_string(custom_field).constantize }.not_to raise_error
      end

      it "should remove the custom field classes after it is deleted" do
        custom_field
        class_name = filter_class_name_string(custom_field)
        delete_work_package_custom_field(custom_field)
        expect { filter_class_name_string(custom_field).constantize }.to raise_error NameError
      end

      it "should provide the correct available values" do
        custom_field2.save

        clear_cache
        ao = filter_class_name_string(custom_field2).constantize.available_operators.map(&:name)
        CostQuery::Operator.null_operators.each do |o|
          expect(ao).to include o.name
        end
      end

      it "should update the available values on change" do
        custom_field2.save

        update_work_package_custom_field("Database", field_format: "string")
        ao = filter_class_name_string(custom_field2).constantize.available_operators.map(&:name)
        CostQuery::Operator.string_operators.each do |o|
          expect(ao).to include o.name
        end
        update_work_package_custom_field("Database", field_format: "int")
        ao = filter_class_name_string(custom_field2).constantize.available_operators.map(&:name)
        CostQuery::Operator.integer_operators.each do |o|
          expect(ao).to include o.name
        end
      end

      it "includes custom fields classes in CustomFieldEntries.all" do
        custom_field
        expect(CostQuery::Filter::CustomFieldEntries.all).
          to include(filter_class_name_string(custom_field).constantize)
      end

      it "includes custom fields classes in Filter.all" do
        custom_field
        expect(CostQuery::Filter.all).
          to include(filter_class_name_string(custom_field).constantize)
      end

      def create_searchable_fields_and_values
        searchable_field = FactoryBot.create(:work_package_custom_field,
                                              field_format: "text",
                                              name: "Searchable Field")
        2.times do
          work_package = create_work_package_with_entry(:cost_entry)
          FactoryBot.create(:work_package_custom_value,
                             custom_field: searchable_field,
                             customized: work_package,
                             value: "125")
        end
        work_package = create_work_package_with_entry(:cost_entry)
        FactoryBot.create(:custom_value,
                           custom_field: searchable_field,
                           value: "non-matching value")
        clear_cache
      end

      it "is usable as filter" do
        create_searchable_fields_and_values
        id = WorkPackageCustomField.find_by(name: "Searchable Field").id
        @query.filter "custom_field_#{id}".to_sym, operator: '=', value: "125"
        expect(@query.result.count).to eq(2)
      end

      it "is usable as filter #2" do
        create_searchable_fields_and_values
        id = WorkPackageCustomField.find_by(name: "Searchable Field").id
        @query.filter "custom_field_#{id}".to_sym, operator: '=', value: "finnlabs"
        expect(@query.result.count).to eq(0)
      end
    end
  end
end
