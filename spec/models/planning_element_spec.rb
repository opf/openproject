#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../spec_helper', __FILE__)

describe PlanningElement do
  let(:project) { FactoryGirl.create(:project) }

  before do
    FactoryGirl.create :priority, is_default: true
    FactoryGirl.create :default_issue_status
  end

  describe '- Relations ' do
    describe '#project' do
      it 'can read the project w/ the help of the belongs_to association' do
        project          = FactoryGirl.create(:project)
        planning_element = FactoryGirl.create(:planning_element,
                                              :project_id => project.id)

        planning_element.reload

        planning_element.project.should == project
      end

      it 'can read the responsible w/ the help of the belongs_to association' do
        user             = FactoryGirl.create(:user)
        planning_element = FactoryGirl.create(:planning_element,
                                              :responsible_id => user.id)

        planning_element.reload

        planning_element.responsible.should == user
      end

      it 'can read the type w/ the help of the belongs_to association' do
        type             = FactoryGirl.create(:type)
        planning_element = FactoryGirl.create(:planning_element,
                                                   :type_id => type.id)

        planning_element.reload

        planning_element.type.should == type
      end

      it 'can read the planning_element_status w/ the help of the belongs_to association' do
        planning_element_status = FactoryGirl.create(:planning_element_status)
        planning_element        = FactoryGirl.create(:planning_element,
                                                 :planning_element_status_id => planning_element_status.id)

        planning_element.reload

        planning_element.planning_element_status.should == planning_element_status
      end
    end
  end

  describe '- Validations ' do
    let(:attributes) {
      {:subject    => 'Planning Element No. 1',
       :start_date => Date.today,
       :due_date   => Date.today + 2.weeks,
       :project_id => project.id}
    }

    it { PlanningElement.new.tap { |pe| pe.send(:assign_attributes, attributes, :without_protection => true) }.should be_valid }

    describe 'subject' do
      it 'is invalid w/o a subject' do
        attributes[:subject] = nil
        planning_element = PlanningElement.new.tap { |pe| pe.send(:assign_attributes, attributes, :without_protection => true) }

        planning_element.should_not be_valid

        planning_element.errors[:subject].should be_present
        planning_element.errors[:subject].should == ["can't be blank"]
      end

      it 'is invalid w/ a subject longer than 255 characters' do
        attributes[:subject] = "A" * 500
        planning_element = PlanningElement.new.tap { |pe| pe.send(:assign_attributes, attributes, :without_protection => true) }

        planning_element.should_not be_valid

        planning_element.errors[:subject].should be_present
        planning_element.errors[:subject].should == ["is too long (maximum is 255 characters)"]
      end
    end

    describe 'start_date' do
      it 'is valid w/o a start_date' do
        attributes[:start_date] = nil
        planning_element = PlanningElement.new.tap { |pe| pe.send(:assign_attributes, attributes, :without_protection => true) }

        planning_element.should be_valid

        planning_element.errors[:start_date].should_not be_present
      end
    end

    describe 'due_date' do
      it 'is valid w/o a due_date' do
        attributes[:due_date] = nil
        planning_element = PlanningElement.new.tap { |pe| pe.send(:assign_attributes, attributes, :without_protection => true) }

        planning_element.should be_valid

        planning_element.errors[:due_date].should_not be_present
      end

      it 'is invalid if start_date is after due_date' do
        attributes[:start_date] = Date.today
        attributes[:due_date]   = Date.today - 1.week
        planning_element = PlanningElement.new.tap { |pe| pe.send(:assign_attributes, attributes, :without_protection => true) }

        planning_element.should_not be_valid

        planning_element.errors[:due_date].should be_present
        planning_element.errors[:due_date].should == ["must be greater than start date"]
      end

      it 'is invalid if planning_element is milestone and due_date is not on start_date' do
        attributes[:type] = FactoryGirl.build(:type, :is_milestone => true)
        attributes[:start_date]            = Date.today
        attributes[:due_date]              = Date.today + 1.week
        planning_element = PlanningElement.new.tap { |pe| pe.send(:assign_attributes, attributes, :without_protection => true) }

        planning_element.should_not be_valid

        planning_element.errors[:due_date].should be_present
        planning_element.errors[:due_date].should == ["is not on start date, although this is required for milestones"]
      end
    end

    describe 'project' do
      it 'is invalid w/o a project' do
        attributes[:project_id] = nil
        planning_element = PlanningElement.new.tap { |pe| pe.send(:assign_attributes, attributes, :without_protection => true) }

        planning_element.should_not be_valid

        planning_element.errors[:project].should be_present
        planning_element.errors[:project].should == ["can't be blank"]
      end
    end

    describe 'parent' do
      it 'is invalid if parent is_milestone' do
        parent = PlanningElement.new.tap do |pe|
          pe.send(:assign_attributes, attributes.merge(:type => FactoryGirl.build(:type, :is_milestone => true)), :without_protection => true)
        end

        attributes[:parent] = parent
        planning_element = PlanningElement.new.tap { |pe| pe.send(:assign_attributes, attributes, :without_protection => true) }

        planning_element.should_not be_valid

        planning_element.errors[:parent].should be_present
        planning_element.errors[:parent].should == ["cannot be a milestone"]
      end

      it 'is invalid if parent is in another project' do
        parent = PlanningElement.new.tap do |pe|
          pe.send(:assign_attributes, attributes.merge(:project_id => FactoryGirl.build(:project)), :without_protection => true)
        end

        attributes[:parent] = parent
        planning_element = PlanningElement.new.tap { |pe| pe.send(:assign_attributes, attributes, :without_protection => true) }

        planning_element.should_not be_valid

        planning_element.errors[:parent].should be_present
        planning_element.errors[:parent].should == ["cannot be in another project"]
      end
    end
  end

  describe 'derived attributes' do
    before do
      @pe1  = FactoryGirl.create(:planning_element, :project_id => project.id)
      @pe11 = FactoryGirl.create(:planning_element, :project_id => project.id, :parent_id => @pe1.id)
      @pe12 = FactoryGirl.create(:planning_element, :project_id => project.id, :parent_id => @pe1.id)
    end

    describe 'start_date' do
      it 'equals the minimum start date of all children' do
        @pe11.reload
        @pe11.update_attributes(:start_date => Date.new(2000, 01, 20), :due_date => Date.new(2001, 01, 20))
        @pe12.reload
        @pe12.update_attributes(:start_date => Date.new(2000, 03, 20), :due_date => Date.new(2001, 03, 20))

        @pe1.reload
        @pe1.start_date.should == @pe11.start_date
      end
    end

    describe 'due_date' do
      it 'equals the maximum end date of all children' do
        @pe11.reload
        @pe11.update_attributes(:start_date => Date.new(2000, 01, 20), :due_date => Date.new(2001, 01, 20))
        @pe12.reload
        @pe12.update_attributes(:start_date => Date.new(2000, 03, 20), :due_date => Date.new(2001, 03, 20))

        @pe1.reload
        @pe1.due_date.should == @pe12.due_date
      end
    end
  end

  describe 'alternate dates' do
    describe 'auto-creation' do
      let(:attributes) {
        {:subject    => 'Planning Element No. 1',
         :start_date => Date.today,
         :due_date   => Date.today + 2.weeks,
         :project_id => project.id}
      }

      it 'creates an alternate date whenever a planning element is created' do
        pe = PlanningElement.new.tap { |pe| pe.send(:assign_attributes, attributes, :without_protection => true) }
        pe.save

        pe.reload
        pe.alternate_dates.should_not be_empty
        pe.alternate_dates.size.should == 1

        ad = pe.alternate_dates.last
        ad.start_date.should == pe.start_date
        ad.due_date.should == pe.due_date
      end

      it 'creates an alternate date whenever start or end date is updated' do
        pe = PlanningElement.new.tap { |pe| pe.send(:assign_attributes, attributes, :without_protection => true) }
        pe.save

        pe.reload
        pe.update_attributes(:start_date => Date.today + 1.day,
                             :due_date   => Date.today + 1.day + 2.weeks)

        pe.alternate_dates.should_not be_empty
        pe.alternate_dates.size.should == 2

        ad = pe.alternate_dates.last
        ad.start_date.should == pe.start_date
        ad.due_date.should == pe.due_date
      end

      it 'does not create an alternate date when other attributes are changed' do
        pe = PlanningElement.new.tap { |pe| pe.send(:assign_attributes, attributes, :without_protection => true) }
        pe.save

        pe.reload
        pe.update_attributes(:subject => 'Things')

        pe.alternate_dates.size.should == 1
      end
    end

    describe 'at_time scope' do
      let(:changes) { [
          {:time       => Date.new(2011,  1, 1).to_time,
           :start_date => Date.new(2012,  1, 1),
           :due_date   => Date.new(2012,  1, 2),
           :due_date   => Date.new(2012,  1, 2)},

          {:time       => Date.new(2011,  1, 2).to_time,
           :start_date => Date.new(2012,  2, 1),
           :due_date   => Date.new(2012,  2, 2),
           :due_date   => Date.new(2012,  2, 2)},

          {:time       => Date.new(2011,  1, 3).to_time,
           :start_date => Date.new(2011, 12, 1),
           :due_date   => Date.new(2012, 12, 2),
           :due_date   => Date.new(2011, 12, 2)}
        ] }

      before do
        # create proper planning element history and journals
        initial = changes.first
        pe = FactoryGirl.create(:planning_element,
                            :start_date => initial[:start_date],
                            :due_date   => initial[:due_date],
                            :created_at => initial[:time],
                            :updated_at => initial[:time])

        begin
          PlanningElement.record_timestamps = false
          # This will keep an api builder intact when calling partials
          pe.reload
          changes[1..-1].each do |change|
            pe[:start_date] = change[:start_date]
            pe[:due_date]   = change[:due_date]
            pe[:updated_at] = change[:time]
            pe.save
            pe.reload
          end
        ensure
          PlanningElement.record_timestamps = true
        end

        # Kill auto-generated alterate dates. We'll create our own
        pe.alternate_dates.delete_all

        changes.each do |change|
          FactoryGirl.create(:alternate_date,
                         :planning_element_id => pe.id,
                         :start_date => change[:start_date],
                         :due_date   => change[:due_date],
                         :created_at => change[:time],
                         :updated_at => change[:time])
        end

        pe.alternate_dates.reload

        @pe = pe
      end

      it 'returns the current data when timestamp is after last edit' do
        fetched = PlanningElement.at_time(changes.last[:time] + 1.day).find(@pe.id)

        fetched.start_date.should == @pe.start_date
        fetched.due_date.should   == @pe.due_date
        fetched.updated_at        == @pe.updated_at
        fetched.should be_readonly
      end

      it 'returns nothing when timestamp is before first edit' do
        expect {
          PlanningElement.at_time(changes.first[:time] - 1.day).find(@pe.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'returns intial data when timestamp is between first and second edit' do
        edit = changes.first
        fetched = PlanningElement.at_time(edit[:time] + 1.hour).find(@pe.id)

        fetched.start_date.should == edit[:start_date]
        fetched.due_date.should   == edit[:due_date]
        fetched.updated_at        == edit[:updated_at]
        fetched.should be_readonly
      end

      it 'returns intermediate data when timestamp is between second and last edit' do
        edit = changes.second
        fetched = PlanningElement.at_time(edit[:time] + 1.hour).find(@pe.id)

        fetched.start_date.should == edit[:start_date]
        fetched.due_date.should   == edit[:due_date]
        fetched.updated_at       == edit[:updated_at]
        fetched.should be_readonly
      end
    end
  end

  describe 'scenarios' do
    let(:project) { FactoryGirl.create(:project) }
    let(:planning_element) { FactoryGirl.create(:planning_element,
                                            :project_id => project.id) }

    describe 'w/o scenarios' do
      describe '#scenarios' do
        it 'returns an empty array' do
          planning_element.scenarios.should be_empty
          planning_element.scenarios.should == []
        end
      end

      describe '#all_scenarios' do
        it 'returns an empty array' do
          planning_element.all_scenarios.should be_empty
          planning_element.all_scenarios.should == []
        end
      end
    end

    describe 'w/ scenarios' do
      let(:scenario_a) {FactoryGirl.create(:scenario,
                                       :project_id => project.id) }
      let(:scenario_b) {FactoryGirl.create(:scenario,
                                       :project_id => project.id) }

      before { scenario_a; scenario_b }

      describe "w/o alternate dates" do
        describe '#scenarios' do
          it 'returns an empty array' do
            planning_element.scenarios.should be_empty
            planning_element.scenarios.should == []
          end
        end

        describe '#all_scenarios' do
          it 'returns an with all scenario w/o dates' do
            scenarios = planning_element.all_scenarios
            scenarios.size.should == 2

            first = scenarios.first
            first.scenario.should == scenario_a
            first.planning_element.should == planning_element
            first.start_date.should be_nil
            first.due_date.should be_nil

            second = scenarios.second
            second.scenario.should == scenario_b
            second.planning_element.should == planning_element
            second.start_date.should be_nil
            second.due_date.should be_nil
          end
        end
      end

      describe 'w/ alternate dates' do
        let(:alternate_date) { FactoryGirl.create(:alternate_date,
                                              :planning_element_id => planning_element.id,
                                              :scenario_id         => scenario_a.id) }

        before { alternate_date; planning_element.reload }

        describe '#scenarios' do
          it 'returns an array w/ one element' do
            scenarios = planning_element.scenarios
            scenarios.size.should == 1

            first = scenarios.first

            first.scenario.should == scenario_a
            first.planning_element.should == planning_element

            first.start_date.should == alternate_date.start_date
            first.due_date.should == alternate_date.due_date
          end
        end

        describe '#all_scenarios' do
          it 'returns an array' do
            scenarios = planning_element.all_scenarios
            scenarios.size.should == 2

            first = scenarios.first

            first.scenario.should == scenario_a
            first.planning_element.should == planning_element

            first.start_date.should == alternate_date.start_date
            first.due_date.should == alternate_date.due_date

            second = scenarios.second

            second.scenario.should == scenario_b
            second.planning_element.should == planning_element

            second.start_date.should be_nil
            second.due_date.should be_nil
          end
        end
      end
    end
  end

  describe 'scenarios=' do
    let(:project) { FactoryGirl.create(:project) }
    let(:planning_element) { FactoryGirl.create(:planning_element,
                                            :project_id => project.id) }
    let(:scenario) { FactoryGirl.create(:scenario,
                                    :project_id => project.id) }

    it 'creates alternate dates if there are none' do
      planning_element; scenario

      planning_element.reload
      planning_element.alternate_dates.scenaric.should be_empty

      planning_element.scenarios = [
        {'id' => scenario.id, 'start_date' => Date.new(2012, 1, 2), 'due_date' => Date.new(2012, 1, 3) }
      ]

      planning_element.save!

      planning_element.reload
      planning_element.alternate_dates.scenaric.should_not be_empty
      planning_element.alternate_dates.scenaric.size.should == 1

      alternate_date = planning_element.alternate_dates.scenaric.first

      alternate_date.scenario.should         == scenario
      alternate_date.start_date.should       == Date.new(2012, 1, 2)
      alternate_date.due_date.should         == Date.new(2012, 1, 3)
      alternate_date.planning_element.should == planning_element
    end

    it 'updates alternate dates if there are some' do
      alternate_date = FactoryGirl.create(:alternate_date,
                                      :planning_element_id => planning_element.id,
                                      :scenario_id => scenario.id,
                                      :start_date  => Date.new(2012, 1, 2),
                                      :due_date    => Date.new(2012, 1, 3))

      planning_element.reload
      planning_element.alternate_dates.scenaric.size.should  == 1
      planning_element.alternate_dates.scenaric.first.should == alternate_date

      planning_element.scenarios = [
        {'id' => scenario.id, 'start_date' => Date.new(2012, 2, 2), 'due_date' => Date.new(2012, 2, 3) }
      ]

      planning_element.save!

      planning_element.reload
      planning_element.alternate_dates.scenaric.should_not be_empty
      planning_element.alternate_dates.scenaric.size.should == 1

      alternate_date.reload
      planning_element.alternate_dates.scenaric.first.should == alternate_date

      alternate_date.scenario.should         == scenario
      alternate_date.start_date.should       == Date.new(2012, 2, 2)
      alternate_date.due_date.should         == Date.new(2012, 2, 3)
      alternate_date.planning_element.should == planning_element
    end

    it 'deletes alternate_dates, if they are marked for destruction' do
      alternate_date = FactoryGirl.create(:alternate_date,
                                      :planning_element_id => planning_element.id,
                                      :scenario_id => scenario.id,
                                      :start_date  => Date.new(2012, 1, 2),
                                      :due_date    => Date.new(2012, 1, 3))

      planning_element.reload
      planning_element.alternate_dates.scenaric.size.should  == 1
      planning_element.alternate_dates.scenaric.first.should == alternate_date

      planning_element.scenarios = [
        {'id' => scenario.id,
         'start_date' => Date.new(2012, 2, 2),
         'due_date' => Date.new(2012, 2, 3),
         '_destroy' => '1'}
      ]

      planning_element.save!

      planning_element.reload
      planning_element.alternate_dates.scenaric.should be_empty
      planning_element.alternate_dates.scenaric.size.should == 0

      expect { alternate_date.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'journal' do
    let(:responsible) { FactoryGirl.create(:user) }
    let(:type)     { FactoryGirl.create(:type) }
    let(:pe_status)   { FactoryGirl.create(:planning_element_status) }

    let(:pe) { FactoryGirl.create(:planning_element,
                                  :subject                         => "Plan A",
                                  :author                          => responsible,
                                  :description                     => "This won't work out",
                                  :start_date                      => Date.new(2012, 1, 24),
                                  :due_date                        => Date.new(2012, 1, 31),
                                  :project_id                      => project.id,
                                  :responsible_id                  => responsible.id,
                                  :type_id                         => type.id,
                                  :planning_element_status_id      => pe_status.id,
                                  :planning_element_status_comment => 'All lost'
                                  ) }

    it "has an initial journal, so that it's creation shows up in activity" do
      pe.journals.size.should == 1

      changes = pe.journals.first.changed_data.to_hash

      changes.size.should == 13

      changes.should include(:subject)
      changes.should include(:author_id)
      changes.should include(:description)
      changes.should include(:start_date)
      changes.should include(:due_date)
      changes.should include(:done_ratio)
      changes.should include(:status_id)
      changes.should include(:priority_id)
      changes.should include(:project_id)
      changes.should include(:responsible_id)
      changes.should include(:type_id)
      changes.should include(:planning_element_status_id)
      changes.should include(:planning_element_status_comment)
    end

    it 'stores updates in journals' do
      pe.reload
      pe.update_attribute(:due_date, Date.new(2012, 2, 1))

      pe.journals.size.should == 2
      changes = pe.journals.last.changed_data.to_hash

      changes.size.should == 1

      changes.should include(:due_date)

      changes[:due_date].first.should == Date.new(2012, 1, 31)
      changes[:due_date].last.should  == Date.new(2012, 2, 1)
    end

    describe 'planning element hierarchies' do
      let(:child_pe) { FactoryGirl.create(:planning_element,
                                          :parent_id         => pe.id,
                                          :subject           => "Plan B",
                                          :description       => "This will work out",
                                          # interval is the same as parent, so that
                                          # dates are not updated
                                          :start_date        => Date.new(2012, 1, 24),
                                          :due_date          => Date.new(2012, 1, 31),
                                          :project_id        => project.id,
                                          :responsible_id    => responsible.id
                                         ) }

      it 'creates a journal in the parent when end date is changed indirectly' do
        child_pe # trigger creation of child and parent

        # sanity check
        child_pe.journals.size.should == 1
        pe.journals.size.should == 2

        # update child
        child_pe.reload
        child_pe.update_attribute(:start_date, Date.new(2012, 1, 1))

        # reload parent to avoid stale journal caches
        pe.reload

        pe.journals.size.should == 3
        changes = pe.journals.last.changed_data.to_hash

        changes.size.should == 1
        changes.should include(:start_date)
      end

    end

    describe "a planning elements' journals includes changes to associated alternate dates start/due date" do
      let(:journal_planning_element) { FactoryGirl.create(:planning_element) }
      let(:journal_scenario) { FactoryGirl.create(:scenario) }
      # PlanningElements create a alternate_date on save by default, so just use that
      it "should create a journal entry if a scenario gets assigned to an alternate date" do
        pending "Fails because of normalized AAJ implementation"

        alternate_date = journal_planning_element.alternate_dates(true).first.tap do |ad|
          ad.scenario = journal_scenario
        end
        journal_planning_element.save!
        journal_planning_element.journals.size.should == 2

        journal_planning_element.journals[0].changed_data.keys.select {|k| !!(/^scenario_(\d*)_(start|due)_date$/.match k.to_s) }.should be_empty

        (date_keys = journal_planning_element.journals[1].changed_data.keys.select do |k|
          !!(/^scenario_(\d*)_(start|due)_date$/.match k.to_s)
        end).should_not be_empty
        date_keys.size.should == 2
        date_keys.each do |k|
          journal_planning_element.journals[1].changed_data[k][0].should == nil
          journal_planning_element.journals[1].changed_data[k][1].acts_like_date?.should be_true
        end
      end

      it "should create a journal entry if a scenario gets removed from an alternate date" do
        pending "Fails because of normalized AAJ implementation"

        # PlanningElements create a alternate_date on save by default, so just use that
        alternate_date = journal_planning_element.alternate_dates(true).first.tap do |ad|
          ad.scenario = journal_scenario
        end
        journal_planning_element.save!
        alternate_date.mark_for_destruction
        journal_planning_element.save!

        (date_keys = journal_planning_element.journals[2].changed_data.keys.select do |k|
          !!(/^scenario_(\d*)_(start|due)_date$/.match k.to_s)
        end)

        date_keys.size.should == 2

        date_keys.each do |k|
          journal_planning_element.journals[2].changed_data[k][0].acts_like_date?.should be_true
          journal_planning_element.journals[2].changed_data[k][1].should == nil
        end
      end

      it "should create seperate journal entries for start_date and due_date if only one of 'em is modified" do
        pending "Fails because of normalized AAJ implementation"

        # PlanningElements create an alternate_date on save by default, so just use that
        alternate_date = journal_planning_element.alternate_dates(true).first.tap do |ad|
          ad.start_date = Date.today
          ad.due_date = Date.today + 1.month
          ad.scenario = journal_scenario
        end
        journal_planning_element.save!

        old_start = alternate_date.start_date
        old_end = alternate_date.due_date

        alternate_date.start_date = new_start = alternate_date.start_date + 1.day
        journal_planning_element.save!

        (date_keys = (start_date_journal = journal_planning_element.journals.last).changed_data.keys.select do |k|
          !!(/^scenario_(\d*)_(start|due)_date$/.match k.to_s)
        end)

        date_keys.size.should == 1

        start_date_journal.changed_data[date_keys.first][0].acts_like_date?.should be_true
        start_date_journal.changed_data[date_keys.first][0].should == old_start
        start_date_journal.changed_data[date_keys.first][1].acts_like_date?.should be_true
        start_date_journal.changed_data[date_keys.first][1].should == new_start
      end
    end
  end

  describe ' - Instance Methods' do
    it_should_behave_like "a model with non-negative duration"

    describe 'trash' do
    end
  end

  describe 'acts as paranoid trash' do
    before(:each) do
      @pe1 = FactoryGirl.create(:planning_element,
                            :project_id => project.id,
                            :start_date => Date.new(2011, 1, 1),
                            :due_date   => Date.new(2011, 2, 1),
                            :subject    => "Numero Uno")
    end

    it 'should set deleted_at on trash' do
      @pe1.reload
      @pe1.trash

      @pe1.deleted_at.should_not be_nil
      expect { PlanningElement.without_deleted.find(@pe1.id) }.to raise_error(ActiveRecord::RecordNotFound)
      PlanningElement.find(@pe1.id).should_not be_nil
    end

    it 'should keep associated objects' do
      @pe1.reload
      @pe1.update_attribute(:start_date, Date.new(2011, 2, 1))
      @pe1.reload
      @pe1.update_attribute(:due_date, Date.new(2012, 2, 1))

      pe11  = FactoryGirl.create(:planning_element,
                             :project_id => project.id,
                             :parent_id  => @pe1.id,
                             :start_date => Date.new(2011, 1, 1),
                             :due_date   => Date.new(2011, 2, 1))
      update_journal = @pe1.journals.last

      @pe1.reload
      @pe1.trash

      pe11.should_not be_nil
      update_journal.should_not be_nil
    end

    it 'should create a journal when marked as deleted' do
      @pe1.reload
      @pe1.trash

      @pe1.journals.reload
      @pe1.journals.last.changed_data.should be_has_key(:deleted_at)
    end

    it 'should adjust parent start and due dates' do
      @pe1.reload
      @pe1.update_attributes(:start_date => Date.new(2011, 5, 1),
                             :due_date   => Date.new(2011, 6, 20))

      pe11  = FactoryGirl.create(:planning_element,
                             :project_id => project.id,
                             :parent_id  => @pe1.id,
                             :start_date => nil,
                             :due_date => Date.new(2011, 1, 1))
      pe12  = FactoryGirl.create(:planning_element,
                             :project_id => project.id,
                             :parent_id  => @pe1.id,
                             :start_date => Date.new(2012, 2, 1),
                             :due_date   => Date.new(2012, 6, 1))
      pe13  = FactoryGirl.create(:planning_element,
                             :project_id => project.id,
                             :parent_id  => @pe1.id,
                             :start_date   => Date.new(2013, 2, 1),
                             :due_date => nil)

      @pe1.reload

      @pe1.start_date.should == pe11.due_date
      @pe1.due_date.should == pe13.start_date

      pe11.reload
      pe11.trash
      pe13.reload
      pe13.trash

      @pe1.reload

      @pe1.start_date.should == pe12.start_date
      @pe1.due_date.should == pe12.due_date
    end

    it 'should keep start and due date when all children are deleted' do
      start_date = Date.new(2000, 1, 1)
      due_date = Date.new(2013, 2, 1)

      pe11  = FactoryGirl.create(:planning_element,
                             :project_id => project.id,
                             :start_date => start_date,
                             :due_date   => due_date,
                             :parent_id  => @pe1.id)

      @pe1.reload

      @pe1.start_date.should == start_date
      @pe1.due_date.should == due_date

      pe11.reload
      pe11.trash

      @pe1.reload

      @pe1.start_date.should == start_date
      @pe1.due_date.should == due_date
    end

    it 'should not restore child elements whose parent is deleted' do
      pe11  = FactoryGirl.create(:planning_element,
                             :project_id => project.id,
                             :parent_id  => @pe1.id,
                             :start_date => Date.new(2011, 1, 1),
                             :due_date   => Date.new(2011, 2, 1))
      @pe1.reload
      @pe1.trash

      pe11.reload

      expect {pe11.restore!}.to raise_error("You cannot restore an element whose parent is deleted. Restore the parent first!")
    end

    it 'should restore elements without touching the children' do
      pe11  = FactoryGirl.create(:planning_element,
                             :project_id => project.id,
                             :parent_id  => @pe1.id,
                             :start_date => Date.new(2011, 1, 1),
                             :due_date   => Date.new(2011, 2, 1))

      @pe1.reload
      @pe1.trash

      @pe1 = PlanningElement.find(@pe1.id)
      @pe1.restore!

      pe11.reload

      pe11.deleted_at.should_not be_nil
      @pe1.deleted_at.should be_nil
    end

    it 'moves all child elements to trash' do
      pe1   = FactoryGirl.create(:planning_element, :project_id => project.id)
      pe11  = FactoryGirl.create(:planning_element, :project_id => project.id, :parent_id => pe1.id)
      pe12  = FactoryGirl.create(:planning_element, :project_id => project.id, :parent_id => pe1.id)
      pe121 = FactoryGirl.create(:planning_element, :project_id => project.id, :parent_id => pe12.id)
      pe2   = FactoryGirl.create(:planning_element, :project_id => project.id)

      pe1.reload
      pe1.trash

      pe1.children.reload

      [pe1, pe11, pe12, pe121].each do |pe|
        PlanningElement.without_deleted.find_by_id(pe.id).should be_nil
        PlanningElement.find_by_id(pe.id).should_not be_nil
      end

      PlanningElement.without_deleted.find_by_id(pe2.id).should == pe2
    end

    it 'should delete the object permanantly when using destroy' do
      @pe1.destroy

      PlanningElement.without_deleted.find_by_id(@pe1.id).should be_nil
      PlanningElement.find_by_id(@pe1.id).should be_nil
    end

    it 'destroys all child elements' do
      pe1   = FactoryGirl.create(:planning_element, :project_id => project.id)
      pe11  = FactoryGirl.create(:planning_element, :project_id => project.id, :parent_id => pe1.id)
      pe12  = FactoryGirl.create(:planning_element, :project_id => project.id, :parent_id => pe1.id)
      pe121 = FactoryGirl.create(:planning_element, :project_id => project.id, :parent_id => pe12.id)
      pe2   = FactoryGirl.create(:planning_element, :project_id => project.id)

      pe1.destroy

      [pe1, pe11, pe12, pe121].each do |pe|
        PlanningElement.without_deleted.find_by_id(pe.id).should be_nil
        PlanningElement.find_by_id(pe.id).should be_nil
      end

      PlanningElement.without_deleted.find_by_id(pe2.id).should == pe2
    end
  end
end
