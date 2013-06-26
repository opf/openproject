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

require 'spec_helper'

describe Project do
  let(:project) { FactoryGirl.build(:project) }
  let(:admin) { FactoryGirl.create(:admin) }

  describe Project::STATUS_ACTIVE do
    it "equals 1" do
      # spec that STATUS_ACTIVE has the correct value
      Project::STATUS_ACTIVE.should == 1
    end
  end

  describe "#active?" do
    before do
      # stub out the actual value of the constant
      stub_const('Project::STATUS_ACTIVE', 42)
    end

    it "is active when :status equals STATUS_ACTIVE" do
      project = FactoryGirl.create :project, :status => 42
      project.should be_active
    end

    it "is not active when :status doesn't equal STATUS_ACTIVE" do
      project = FactoryGirl.create :project, :status => 99
      project.should_not be_active
    end
  end

  describe "associated_project_candidates" do
    let(:project_type) { FactoryGirl.create(:project_type, :allows_association => true) }

    it "should not include the project" do
      project.project_type = project_type
      project.save!

      project.associated_project_candidates(admin).should be_empty
    end
  end
end
