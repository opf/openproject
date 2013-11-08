#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require File.expand_path('../../support/shared/become_member', __FILE__)

describe Project do
  include BecomeMember

  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }

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

    before do
      FactoryGirl.create(:type_standard)
    end

    it "should not include the project" do
      project.project_type = project_type
      project.save!

      project.associated_project_candidates(admin).should be_empty
    end
  end

  describe "add_work_package" do
    let(:project) { FactoryGirl.create(:project_with_types) }

    it "should return a new work_package" do
      project.add_work_package.should be_a(WorkPackage)
    end

    it "should not be saved" do
      project.add_work_package.should be_new_record
    end

    it "returned work_package should have project set to self" do
      project.add_work_package.project.should == project
    end

    it "returned work_package should have type set to project's first type" do
      project.add_work_package.type.should == project.types.first
    end

    it "returned work_package should have type set to provided type" do
      specific_type = FactoryGirl.build(:type)
      project.types << specific_type

      project.add_work_package(:type => specific_type).type.should == specific_type
    end

    it "should raise an error if the provided type is not one of the project's types" do
      # Load project first so that the new type is not automatically included
      project
      specific_type = FactoryGirl.create(:type)

      expect { project.add_work_package(:type => specific_type) }.to raise_error ActiveRecord::RecordNotFound
    end

    it "returned work_package should have type set to provided type_id" do
      specific_type = FactoryGirl.build(:type)
      project.types << specific_type

      project.add_work_package(:type_id => specific_type.id).type.should == specific_type
    end

    it "should set all the other attributes" do
      attributes = { :blubs => double('blubs') }

      new_work_package = FactoryGirl.build_stubbed(:work_package)
      new_work_package.should_receive(:attributes=).with(attributes)

      WorkPackage.stub(:new).and_yield(new_work_package)

      project.add_work_package(attributes)
    end
  end

  describe :find_visible do
    it 'should find the project by id if the user is project member' do
      become_member_with_permissions(project, user, :view_work_packages)

      Project.find_visible(user, project.id).should == project
    end

    it 'should find the project by identifier if the user is project member' do
      become_member_with_permissions(project, user, :view_work_packages)

      Project.find_visible(user, project.identifier).should == project
    end

    it 'should not find the project by identifier if the user is no project member' do
      expect { Project.find_visible(user, project.identifier) }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'should not find the project by id if the user is no project member' do
      expect { Project.find_visible(user, project.id) }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context 'when the wiki module is enabled' do
    let(:project) { FactoryGirl.create(:project, :without_wiki) }

    before :each do
      project.enabled_module_names = project.enabled_module_names | ['wiki']
      project.save
      project.reload
    end

    it 'creates a wiki' do
      project.wiki.should be_present
    end

    it 'creates a wiki menu item named like the default start page' do
      project.wiki.wiki_menu_items.should be_one
      project.wiki.wiki_menu_items.first.title.should == project.wiki.start_page
    end
  end

  describe :copy do
    let(:project) { FactoryGirl.create(:project_with_types) }
    let(:copy) { Project.new }

    it "should be able to be copied" do
      copy.name = "foo"
      copy.identifier = "foo"
      copy.copy(project)

      copy.should be_valid
      copy.should_not be_new_record
    end
  end

  describe :copy_attributes do
    let(:project) do
      project = FactoryGirl.create(:project_with_types)
      work_package_custom_field = FactoryGirl.create(:work_package_custom_field)
      project.work_package_custom_fields << work_package_custom_field
      project.save
      project
    end
    let(:copy) do
      copy = Project.new
      copy.name = "foo"
      copy.identifier = "foo"
      return copy
    end

    it "should copy all relevant attributes from another project" do
      copy.send :copy_attributes, project
      copy.save

      copy.types.should == project.types
      copy.work_package_custom_fields.should == project.work_package_custom_fields
    end
  end

  describe :copy_associations do
    let(:project) { FactoryGirl.create(:project_with_types) }
    let(:copy) do
      copy = Project.new
      copy.name = "foo"
      copy.identifier = "foo"
      copy.copy_attributes(project)
      copy.save
      return copy
    end

    describe :copy_work_packages do
      it "should copy work_packages from another project" do
        wp1 = FactoryGirl.create(:work_package, :project => project)
        wp2 = FactoryGirl.create(:work_package, :project => project)
        wp3 = FactoryGirl.create(:work_package, :project => project)
        relation = FactoryGirl.create(:relation, :from => wp1, :to => wp2)
        wp1.parent = wp3
        wp1.category = FactoryGirl.create(:category, :project => project)
        wp1.fixed_version = FactoryGirl.create(:version, :project => project)
        [wp1, wp2, wp3].each { |wp| project.work_packages << wp }
        copy.send :copy_work_packages, project
        copy.save

        copy.work_packages.count.should == project.work_packages.count
      end
    end

    describe :copy_timelines do
      it "should copy timelines from another project" do
        timeline = FactoryGirl.create(:timeline, :project => project)
        # set options to nil, is known to have been buggy
        timeline.send :write_attribute, :options, nil

        copy.send(:copy_timelines, project)
        copy.save

        copy.timelines.count.should == project.timelines.count
      end
    end
  end
end
