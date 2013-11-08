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

describe Project::Copy do
  describe :copy do
    let(:project) { FactoryGirl.create(:project_with_types) }
    let(:copy) { Project.new }

    before do
      copy.name = "foo"
      copy.identifier = "foo"
      copy.copy(project)
    end

    subject { copy }

    it "should be able to be copied" do

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
      copy
    end

    before do
      copy.send :copy_attributes, project
      copy.save
    end

    it "should copy all relevant attributes from another project" do
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
      copy
    end

    describe :copy_work_packages do
      before do
        version = FactoryGirl.create(:version, :project => project)
        wp1 = FactoryGirl.create(:work_package, :project => project, :fixed_version => version)
        wp2 = FactoryGirl.create(:work_package, :project => project, :fixed_version => version)
        wp3 = FactoryGirl.create(:work_package, :project => project, :fixed_version => version)
        relation = FactoryGirl.create(:relation, :from => wp1, :to => wp2)
        wp1.parent = wp3
        wp1.category = FactoryGirl.create(:category, :project => project)
        [wp1, wp2, wp3].each { |wp| project.work_packages << wp }

        copy.send :copy_work_packages, project
        copy.save
      end

      it do
        copy.work_packages.each { |wp| wp.should(be_valid) && wp.fixed_version.should(be_nil) }
        copy.work_packages.count.should == project.work_packages.count
      end
    end

    describe :copy_timelines do
      before do
        timeline = FactoryGirl.create(:timeline, :project => project)
        # set options to nil, is known to have been buggy
        timeline.send :write_attribute, :options, nil

        copy.send(:copy_timelines, project)
        copy.save
      end

      subject { copy.timelines.count }

      it { should == project.timelines.count }
    end
  end
end