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

describe WorkPackage do
  let(:stub_work_package) { FactoryGirl.build_stubbed(:work_package) }
  let(:stub_user) { FactoryGirl.build_stubbed(:user) }
  let(:stub_version) { FactoryGirl.build_stubbed(:version) }

  describe :assignable_users do
    it 'should return all users the project deems to be assignable' do
      stub_work_package.project.stub!(:assignable_users).and_return([stub_user])

      stub_work_package.assignable_users.should include(stub_user)
    end
  end

  describe :assignable_versions do
    def stub_shared_versions(v = nil)
      versions = v ? [v] : []

      # open seems to be defined on the array's singleton class
      # as such it seems not possible to stub it
      # achieving the same here
      versions.define_singleton_method :open do
        self
      end

      stub_work_package.project.stub!(:shared_versions).and_return(versions)
    end

    it "should return all the project's shared versions" do
      stub_shared_versions(stub_version)

      stub_work_package.assignable_versions.should == [stub_version]
    end

    it "should return the current fixed_version" do
      stub_shared_versions

      stub_work_package.stub!(:fixed_version_id_was).and_return(5)
      Version.stub!(:find_by_id).with(5).and_return(stub_version)

      stub_work_package.assignable_versions.should == [stub_version]
    end
  end

  describe :copy_from do
    let(:source) { FactoryGirl.build(:work_package) }
    let(:sink) { FactoryGirl.build(:work_package) }

    it "should copy project" do
      source.project_id = 1

      sink.copy_from(source)

      sink.project_id.should == source.project_id
    end

    it "should not copy project if explicitly excluded" do
      source.project_id = 1
      orig_project_id = sink.project_id

      sink.copy_from(source, :exclude => [:project_id])

      sink.project_id.should == orig_project_id
    end
  end
end
