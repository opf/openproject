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

describe Scenario do
  describe '- Relations ' do
    describe '#project' do
      it 'can read the project w/ the help of the belongs_to association' do
        project  = FactoryGirl.create(:project)
        scenario = FactoryGirl.create(:scenario,
                                  :project_id => project.id)

        scenario.reload

        scenario.project.should == project
      end
    end

    describe '#alternate_dates' do
      it 'can read alternate_dates w/ the help of the has_many association' do
        scenario = FactoryGirl.create(:scenario)
        alternate_date = FactoryGirl.create(:alternate_date,
                                        :scenario_id => scenario.id)

        scenario.reload

        scenario.alternate_dates.size.should == 1
        scenario.alternate_dates.first.should == alternate_date
      end

      it 'deletes associated alternate_dates' do
        scenario = FactoryGirl.create(:scenario)
        alternate_date = FactoryGirl.create(:alternate_date,
                                        :scenario_id => scenario.id)
        scenario.reload

        scenario.destroy

        expect { alternate_date.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '- Validations ' do
    let(:attributes) {
      {:name => 'Scenario No. 1',
       :project_id => 1}
    }

    before { FactoryGirl.create(:project, :id => 1) }

    it { Scenario.new.tap { |s| s.send(:assign_attributes, attributes, :without_protection => true) }.should be_valid }

    describe 'name' do
      it 'is invalid w/o a name' do
        attributes[:name] = nil
        scenario = Scenario.new.tap { |s| s.send(:assign_attributes, attributes, :without_protection => true) }

        scenario.should_not be_valid

        scenario.errors[:name].should be_present
        scenario.errors[:name].should == ["can't be blank"]
      end

      it 'is invalid w/ a name longer than 255 characters' do
        attributes[:name] = "A" * 500
        scenario = Scenario.new.tap { |s| s.send(:assign_attributes, attributes, :without_protection => true) }

        scenario.should_not be_valid

        scenario.errors[:name].should be_present
        scenario.errors[:name].should == ["is too long (maximum is 255 characters)"]
      end
    end

    describe 'project' do
      it 'is invalid w/o a project' do
        attributes[:project_id] = nil
        scenario = Scenario.new.tap { |s| s.send(:assign_attributes, attributes, :without_protection => true) }

        scenario.should_not be_valid

        scenario.errors[:project].should be_present
        scenario.errors[:project].should == ["can't be blank"]
      end
    end
  end
end
