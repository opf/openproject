require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery do
  minimal_query

  fixtures :users
  fixtures :cost_types
  fixtures :cost_entries
  fixtures :rates
  fixtures :projects
  fixtures :issues
  fixtures :trackers
  fixtures :time_entries
  fixtures :enumerations
  fixtures :issue_statuses
  fixtures :roles
  fixtures :issue_categories
  fixtures :versions
  fixtures :custom_fields
  fixtures :custom_values

  describe CostQuery::Filter do
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
      [CostQuery::Filter::ProjectId,  Project,            "project_id"    ],
      [CostQuery::Filter::UserId,     User,               "user_id"       ],
      [CostQuery::Filter::CostTypeId, CostType,           "cost_type_id"  ],
      [CostQuery::Filter::IssueId,    Issue,              "issue_id"      ],
      [CostQuery::Filter::ActivityId, TimeEntryActivity,  "activity_id"   ]
    ].each do |filter, model, field|
      describe filter do
        it "should only return entries from the given #{model}" do
          object = model.first
          @query.filter field, :value => object.id
          @query.result.each do |result|
            result[field].to_s.should == object.id.to_s
          end
        end

        it "should allow chaining the same filter" do
          object = model.first
          @query.filter field, :value => object.id
          @query.filter field, :value => object.id
          @query.result.each do |result|
            result[field].to_s.should == object.id.to_s
          end
        end

        it "should return no results for excluding filters" do
          object = model.first
          @query.filter field, :value => object.id
          @query.filter field, :value => object.id + 1
          @query.result.count.should == 0
        end

        it "should compute the correct number of results" do
          object = model.first
          @query.filter field, :value => object.id
          @query.result.count.should == Entry.all.select { |i| i.respond_to? field and i.send(field) == object.id }.count
        end
      end
    end

    describe CostQuery::Filter::AuthorId do
      it "should only return entries from the given author" do
        object = User.first
        @query.filter "author_id", :value => object.id
        @query.result.each do |result|
          result["author_id"].to_s.should == object.id.to_s
        end
      end

      it "should allow chaining the same filter" do
        object = User.first
        @query.filter "author_id", :value => object.id
        @query.filter "author_id", :value => object.id
        @query.result.each do |result|
          result["author_id"].to_s.should == object.id.to_s
        end
      end

      it "should return no results for excluding filters" do
        object = User.first
        @query.filter "author_id", :value => object.id
        @query.filter "author_id", :value => object.id + 1
        @query.result.count.should == 0
      end

      it "should compute the correct number of results" do
        object = User.first
        @query.filter "author_id", :value => object.id
        @query.result.count.should == Entry.all.select { |i| i.issue and i.issue.author == object }.count
      end
    end\

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
      val = CostQuery::Filter::UserId.available_values.first[1].to_i
      @query.filter :user_id, :value => val, :operator => '='
      @query.result.count.should == Entry.all.select { |e| e.user_id == val }.count
    end

    it "filters overridden_costs" do
      @query.filter :overridden_costs, :operator => 'y'
      @query.result.count.should == Entry.all.select { |e| not e.overridden_costs.nil? }.count
    end

    it "filters status" do
      @query.filter :status_id, :operator => 'c'
      @query.result.count.should == Entry.all.select { |e| e.issue.status.is_closed }.count
    end

    it "filters tracker" do
      @query.filter :tracker_id, :operator => '=', :value => Tracker.all.first.id
      @query.result.count.should == Entry.all.select { |e| e.issue.tracker == Tracker.all.first}.count
    end

    it "filters issue authors" do
      @query.filter :author_id, :operator => '=', :value => User.all.first.id
      @query.result.count.should == Entry.all.select { |e| e.issue.author == User.all.first}.count
    end

    it "filters priority" do
      @query.filter :priority_id, :operator => '=', :value => IssuePriority.all.first.id
      @query.result.count.should == Entry.all.select { |e| e.issue.priority == IssuePriority.all.first}.count
    end

    it "filters assigned to" do
      @query.filter :assigned_to_id, :operator => '=', :value => User.all.first.id
      @query.result.count.should == Entry.all.select { |e| e.issue.assigned_to ? e.issue.assigned_to == User.all.first : false }.count
    end

    it "filters category" do
      @query.filter :category_id, :operator => '=', :value => IssueCategory.all.first.id
      @query.result.count.should == Entry.all.select { |e| e.issue.category ? e.issue.category == IssueCategory.all.first : false }.count
    end

    it "filters target version" do
      @query.filter :fixed_version_id, :operator => '=', :value => Version.all.second.id
      @query.result.count.should == Entry.all.select { |e| e.issue.fixed_version ? e.issue.fixed_version == Version.all.second : false }.count
    end

    it "filters subject" do
      @query.filter :subject, :operator => '=', :value => Issue.all.first.subject
      @query.result.count.should == Entry.all.select { |e| e.issue.subject == Issue.all.first.subject}.count
    end

    it "filters start" do
      @query.filter :start_date, :operator => '=d', :value => Issue.all.first.start_date
      @query.result.count.should == Entry.all.select { |e| e.issue.start_date == Issue.all.first.start_date }.count
    end

    it "filters due date" do
      @query.filter :due_date, :operator => '=d', :value => Issue.all.first.due_date
      @query.result.count.should == Entry.all.select { |e| e.issue.due_date == Issue.all.first.due_date }.count
    end

    it "raises an error if operator is not supported" do
      proc { @query.filter :spent_on, :operator => 'c' }.should raise_error(ArgumentError)
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
      before do
        CostQuery::Filter.all.merge CostQuery::Filter::CustomFieldEntries.all
      end

      it "should create classes for custom fields" do
        # Would raise a name error
        CostQuery::Filter::CustomFieldSearchableField
      end

      it "includes custom fields classes in CustomFieldEntries.all" do
        CostQuery::Filter::CustomFieldEntries.all.
          should include(CostQuery::Filter::CustomFieldSearchableField)
      end

      it "includes custom fields classes in Filter.all" do
        CostQuery::Filter::CustomFieldEntries.all.
          should include(CostQuery::Filter::CustomFieldSearchableField)
      end

      it "is usable as filter" do
        @query.filter :custom_field_searchable_field, :operator => '=', :value => "125"
        @query.result.count.should == 8 # see fixtures
      end

      it "is usable as filter #2" do
        @query.filter :custom_field_searchable_field, :operator => '=', :value => "finnlabs"
        @query.result.count.should == 0 # see fixtures
      end
    end
  end
end