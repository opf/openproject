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

describe PlanningElementScenario do
  let(:project)          { FactoryGirl.build(:project) }
  let(:planning_element) { FactoryGirl.build(:planning_element, :project          => project) }
  let(:scenario)         { FactoryGirl.build(:scenario,         :project          => project) }
  let(:alternate_date)   { FactoryGirl.build(:alternate_date,   :scenario         => scenario,
                                                                      :planning_element => planning_element) }

  let(:subject) { PlanningElementScenario.new(alternate_date) }

  it 'delegates start_date to the alternate date' do
    subject.start_date.should == alternate_date.start_date
  end

  it 'delegates start_date= to the alternate date' do
    d = Date.new(1982, 01, 31)
    subject.start_date = d
    alternate_date.start_date.should == d
  end

  it 'delegates due_date to the alternate date' do
    subject.due_date.should == alternate_date.due_date
  end

  it 'delegates due_date= to the alternate date' do
    d = Date.new(1982, 01, 31)
    subject.due_date = d
    alternate_date.due_date.should == d
  end

  it 'delegates duration to the alternate date' do
    subject.duration.should eql alternate_date.duration
  end

  it 'delegates scenario to the alternate date' do
    subject.scenario.should == alternate_date.scenario
  end

  it 'delegates scenario_id to the alternate date' do
    subject.scenario_id.should == alternate_date.scenario_id
  end

  it 'delegates name to the scenario' do
    subject.name.should == scenario.name
  end

  it 'delegates id to the scenario' do
    subject.id.should == scenario.id
  end
end
