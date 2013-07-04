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

describe AvailableProjectStatus do
  describe '- Relations ' do
    describe '#project_type' do
      it 'can read the project_type w/ the help of the belongs_to association' do
        project_type = FactoryGirl.create(:project_type)
        available_project_status = FactoryGirl.create(:available_project_status,
                                                  :project_type_id => project_type.id)

        available_project_status.reload

        available_project_status.project_type.should == project_type
      end
    end

    describe '#reported_project_status' do
      it 'can read the reported_project_status w/ the help of the belongs_to association' do
        reported_project_status  = FactoryGirl.create(:reported_project_status)
        available_project_status = FactoryGirl.create(:available_project_status,
                                                  :reported_project_status_id => reported_project_status.id)

        available_project_status.reload

        available_project_status.reported_project_status.should == reported_project_status
      end
    end
  end

  describe '- Validations ' do
    let(:attributes) {
      { :reported_project_status_id => 2,
        :project_type_id => 1 }
    }

    before {
      FactoryGirl.create(:project_type, :id => 1)
      FactoryGirl.create(:reported_project_status, :id => 2)
    }

    it { AvailableProjectStatus.new.tap { |ps| ps.send(:assign_attributes, attributes, :without_protection => true) }.should be_valid }

    describe 'project_type' do
      it 'is invalid w/o a project_type' do
        attributes[:project_type_id] = nil
        available_project_status = AvailableProjectStatus.new.tap { |ps| ps.send(:assign_attributes, attributes, :without_protection => true) }

        available_project_status.should_not be_valid

        available_project_status.errors[:project_type].should be_present
        available_project_status.errors[:project_type].should == ["can't be blank"]
      end
    end

    describe 'reported_project_status' do
      it 'is invalid w/o a reported_project_status' do
        attributes[:reported_project_status_id] = nil
        available_project_status = AvailableProjectStatus.new.tap { |ps| ps.send(:assign_attributes, attributes, :without_protection => true) }

        available_project_status.should_not be_valid

        available_project_status.errors[:reported_project_status].should be_present
        available_project_status.errors[:reported_project_status].should == ["can't be blank"]
      end
    end
  end
end
