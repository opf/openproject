require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery, :reporting_query_helper => true do
  minimal_query

  let!(:project) { FactoryGirl.create(:project_with_trackers) }
  let!(:user) { FactoryGirl.create(:user, :member_in_project => project) }

  def create_issue_with_entry(entry_type, issue_params={}, entry_params = {})
      issue_params = {:project => project}.merge!(issue_params)
      issue = FactoryGirl.create(:issue, issue_params)
      entry_params = {:issue => issue,
                      :project => issue_params[:project],
                      :user => user}.merge!(entry_params)
      FactoryGirl.create(entry_type, entry_params)
      issue
  end

  describe CostQuery::Filter do
    def create_issue_with_time_entry(issue_params={}, entry_params = {})
      create_issue_with_entry(:time_entry, issue_params, entry_params)
    end

    it "shows all entries when no filter is applied" do
      @query.result.count.should == Entry.count
    end

    it "always sets cost_type" do
      @query.result.each do |result|
        result["cost_type"].should_not be_nil
      end
    end

    it "sets activity_id to -1 for cost entries" do
      @query.result.each do |result|
        result["activity_id"].to_i.should == -1 if result["type"] != "TimeEntry"
      end
    end

    [
      [CostQuery::Filter::ProjectId,  'project',    "project_id",   2],
      [CostQuery::Filter::UserId,     'user',       "user_id",      2],
      [CostQuery::Filter::AuthorId,   'author',     "author_id",    2],
      [CostQuery::Filter::CostTypeId, 'cost_type',  "cost_type_id", 1],
      [CostQuery::Filter::IssueId,    'issue',      "issue_id",     2],
      [CostQuery::Filter::ActivityId, 'activity',   "activity_id",  1],
    ].each do |filter, object_name, field, expected_count|
      describe filter do
        let!(:non_matching_entry) { FactoryGirl.create(:cost_entry) }
        let!(:object) { send(object_name) }
        let!(:author) { FactoryGirl.create(:user, :member_in_project => project) }
        let!(:issue) { FactoryGirl.create(:issue, :project => project,
                                                  :author => author) }
        let!(:cost_type) { FactoryGirl.create(:cost_type) }
        let!(:cost_entry) { FactoryGirl.create(:cost_entry, :issue => issue,
                                                            :user => user,
                                                            :project => project,
                                                            :cost_type => cost_type) }
        let!(:activity) { FactoryGirl.create(:time_entry_activity) }
        let!(:time_entry) { FactoryGirl.create(:time_entry, :issue => issue,
                                                            :user => user,
                                                            :project => project,
                                                            :activity => activity) }

        it "should only return entries from the given #{filter.to_s}" do
          @query.filter field, :value => object.id
          @query.result.each do |result|
            result[field].to_s.should == object.id.to_s
          end
        end

        it "should allow chaining the same filter" do
          @query.filter field, :value => object.id
          @query.filter field, :value => object.id
          @query.result.each do |result|
            result[field].to_s.should == object.id.to_s
          end
        end

        it "should return no results for excluding filters" do
          @query.filter field, :value => object.id
          @query.filter field, :value => object.id + 1
          @query.result.count.should == 0
        end

        it "should compute the correct number of results" do
          @query.filter field, :value => object.id
          @query.result.count.should == expected_count
        end
      end
    end

    it "filters spent_on" do
      @query.filter :spent_on, :operator=> 'w'
      @query.result.count.should == Entry.all.select { |e| e.spent_on.cweek == TimeEntry.all.first.spent_on.cweek }.count
    end

    it "filters created_on" do
      @query.filter :created_on, :operator => 't'
      # we assume that some of our fixtures set created_on to Time.now
      @query.result.count.should == Entry.all.select { |e| e.created_on.to_date == Date.today }.count
    end

    it "filters updated_on" do
      @query.filter :updated_on, :value => Date.today.years_ago(20), :operator => '>d'
      # we assume that our were updated in the last 20 years
      @query.result.count.should == Entry.all.select { |e| e.updated_on.to_date > Date.today.years_ago(20) }.count
    end

    it "filters user_id" do
      old_user = User.current
      # create non-matching entry
      anonymous = FactoryGirl.create(:anonymous)
      create_issue_with_time_entry({}, {:user => anonymous})
      # create matching entry
      create_issue_with_time_entry()
      @query.filter :user_id, :value => user.id, :operator => '='
      @query.result.count.should == 1
    end

    describe "issue-based filters" do
      def create_issues_and_time_entries(entry_count, issue_params={}, entry_params={})
        entry_count.times do
          create_issue_with_entry(:cost_entry, issue_params, entry_params)
        end
      end

      def create_matching_object_with_time_entries(factory, issue_field, entry_count)
        object = FactoryGirl.create(factory)
        create_issues_and_time_entries(entry_count, {issue_field => object})
        object
      end

      it "filters overridden_costs" do
        @query.filter :overridden_costs, :operator => 'y'
        @query.result.count.should == Entry.all.select { |e| not e.overridden_costs.nil? }.count
      end

      it "filters status" do
        matching_status = FactoryGirl.create(:issue_status, :is_closed => true)
        create_issues_and_time_entries(3, :status => matching_status)
        @query.filter :status_id, :operator => 'c'
        @query.result.count.should == 3
      end

      it "filters tracker" do
        matching_tracker = project.trackers.first
        create_issues_and_time_entries(3, :tracker => matching_tracker)
        @query.filter :tracker_id, :operator => '=', :value => matching_tracker.id
        @query.result.count.should == 3
      end

      it "filters issue authors" do
        matching_author = create_matching_object_with_time_entries(:user, :author, 3)
        @query.filter :author_id, :operator => '=', :value => matching_author.id
        @query.result.count.should == 3
      end

      it "filters priority" do
        matching_priority = create_matching_object_with_time_entries(:priority, :priority, 3)
        @query.filter :priority_id, :operator => '=', :value => matching_priority.id
        @query.result.count.should == 3
      end

      it "filters assigned to" do
        matching_user = create_matching_object_with_time_entries(:user, :assigned_to, 3)
        @query.filter :assigned_to_id, :operator => '=', :value => matching_user.id
        @query.result.count.should == 3
      end

      it "filters category" do
        category = create_matching_object_with_time_entries(:issue_category, :category, 3)
        @query.filter :category_id, :operator => '=', :value => category.id
        @query.result.count.should == 3
      end

      it "filters target version" do
        matching_version = FactoryGirl.create(:version, :project => project)
        create_issues_and_time_entries(3, :fixed_version => matching_version)

        @query.filter :fixed_version_id, :operator => '=', :value => matching_version.id
        @query.result.count.should == 3
      end

      it "filters subject" do
        matching_issue = create_issue_with_time_entry(:subject => 'matching subject')
        @query.filter :subject, :operator => '=', :value => 'matching subject'
        @query.result.count.should == 1
      end

      it "filters start" do
        start_date = Date.new(2013, 1, 1)
        matching_issue = create_issue_with_time_entry(:start_date => start_date)
        @query.filter :start_date, :operator => '=d', :value => start_date
        @query.result.count.should == 1
        #Entry.all.select { |e| e.issue.start_date == Issue.all(:order => "id ASC").first.start_date }.count
      end

      it "filters due date" do
        due_date = Date.new(2013, 1, 1)
        matching_issue = create_issue_with_time_entry(:due_date => due_date)
        @query.filter :due_date, :operator => '=d', :value => due_date
        @query.result.count.should == 1
        #Entry.all.select { |e| e.issue.due_date == Issue.all(:order => "id ASC").first.due_date }.count
      end

      it "raises an error if operator is not supported" do
        proc { @query.filter :spent_on, :operator => 'c' }.should raise_error(ArgumentError)
      end
    end

    #filter for specific objects, which can't be null
    [
      CostQuery::Filter::UserId,
      CostQuery::Filter::CostTypeId,
      CostQuery::Filter::IssueId,
      CostQuery::Filter::AuthorId,
      CostQuery::Filter::ActivityId,
      CostQuery::Filter::PriorityId,
      CostQuery::Filter::TrackerId
    ].each do |filter|
      it "should only allow default operators for #{filter}" do
        filter.new.available_operators.uniq.sort.should == CostQuery::Operator.default_operators.uniq.sort
      end
    end

    #filter for specific objects, which might be null
    [
      CostQuery::Filter::AssignedToId,
      CostQuery::Filter::CategoryId,
      CostQuery::Filter::FixedVersionId
    ].each do |filter|
      it "should only allow default+null operators for #{filter}" do
        filter.new.available_operators.uniq.sort.should == (CostQuery::Operator.default_operators + CostQuery::Operator.null_operators).sort
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
        filter.new.available_operators.uniq.sort.should == CostQuery::Operator.time_operators.sort
      end
    end

    describe CostQuery::Filter::CustomFieldEntries do
      let!(:custom_field) { FactoryGirl.create(:issue_custom_field,
                                               :name => 'My custom field') }

      before do
        CostQuery::Filter.all.merge CostQuery::Filter::CustomFieldEntries.all
      end

      after do
        clear_cache
      end

      def clear_cache
        CostReportsController.new.check_cache(true)
        CostQuery::Filter::CustomFieldEntries.all
      end

      def delete_issue_custom_field(name)
        IssueCustomField.find_by_name(name).destroy
        clear_cache
      end

      def update_issue_custom_field(name, options)
        fld = IssueCustomField.find_by_name(name)
        options.each_pair {|k, v| fld.send(:"#{k}=", v) }
        fld.save!
        clear_cache
      end

      it "should create classes for custom fields that get added after starting the server" do
        clear_cache
        # Would raise a name error if class wasn't created
        CostQuery::Filter::CustomFieldMyCustomField
      end

      it "should remove the custom field classes after it is deleted" do
        FactoryGirl.create(:issue_custom_field, :name => "AFreshCustomField")
        clear_cache
        CostQuery::Filter.all.should include CostQuery::Filter::CustomFieldAfreshcustomfield
        delete_issue_custom_field("AFreshCustomField")
        CostQuery::Filter.all.should_not include CostQuery::Filter::CustomFieldAfreshcustomfield
      end

      it "should provide the correct available values" do
        FactoryGirl.create(:issue_custom_field, :name => 'Database',
                                                :field_format => "list",
                                                :possible_values => ['value'])
        clear_cache
        ao = CostQuery::Filter::CustomFieldDatabase.available_operators.map(&:name)
        CostQuery::Operator.null_operators.each do |o|
          ao.should include o.name
        end
      end

      it "should update the available values on change" do
        FactoryGirl.create(:issue_custom_field, :name => 'Database',
                                                :field_format => "list",
                                                :possible_values => ['value'])
        update_issue_custom_field("Database", :field_format => "string")
        ao = CostQuery::Filter::CustomFieldDatabase.available_operators.map(&:name)
        CostQuery::Operator.string_operators.each do |o|
          ao.should include o.name
        end
        update_issue_custom_field("Database", :field_format => "int")
        ao = CostQuery::Filter::CustomFieldDatabase.available_operators.map(&:name)
        CostQuery::Operator.integer_operators.each do |o|
          ao.should include o.name
        end
      end

      it "includes custom fields classes in CustomFieldEntries.all" do
        CostQuery::Filter::CustomFieldEntries.all.
          should include(CostQuery::Filter::CustomFieldMyCustomField)
      end

      it "includes custom fields classes in Filter.all" do
        CostQuery::Filter.all.
          should include(CostQuery::Filter::CustomFieldMyCustomField)
      end

      def create_searchable_fields_and_values
        searchable_field = FactoryGirl.create(:issue_custom_field,
                                              :field_format => "text",
                                              :name => "Searchable Field")
        2.times do
          issue = create_issue_with_entry(:cost_entry)
          FactoryGirl.create(:issue_custom_value,
                             :custom_field => searchable_field,
                             :customized => issue,
                             :value => "125")
        end
        issue = create_issue_with_entry(:cost_entry)
        FactoryGirl.create(:custom_value,
                           :custom_field => searchable_field,
                           :value => "non-matching value")
        clear_cache
      end

      it "is usable as filter" do
        create_searchable_fields_and_values
        @query.filter :custom_field_searchable_field, :operator => '=', :value => "125"
        @query.result.count.should == 2
      end

      it "is usable as filter #2" do
        create_searchable_fields_and_values
        @query.filter :custom_field_searchable_field, :operator => '=', :value => "finnlabs"
        @query.result.count.should == 0
      end
    end
  end
end

