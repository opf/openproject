#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013 the OpenProject Team
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WorkPackage do
  describe 'behavior for #3200' do
    let(:empty_work_package) { WorkPackage.new }

    it do
      empty_work_package.move_to_project_without_transaction(nil).should be_false
    end

    it do
      lambda { empty_work_package.move_to_project_without_transaction(nil) }.should_not raise_error(NoMethodError)
    end
  end

  describe 'validations' do
    let(:work_package) do
      FactoryGirl.build(:work_package)
    end

    describe 'story points' do
      before(:each) do
        work_package.project.enabled_module_names += ["backlogs"]
      end

      it 'allows empty values' do
        work_package.story_points.should be_nil
        work_package.should be_valid
      end

      it 'allows values greater than or equal to 0' do
        work_package.story_points = '0'
        work_package.should be_valid

        work_package.story_points = '1'
        work_package.should be_valid
      end

      it 'allows values less than 10.000' do
        work_package.story_points = '9999'
        work_package.should be_valid
      end

      it 'disallows negative values' do
        work_package.story_points = '-1'
        work_package.should_not be_valid
      end

      it 'disallows greater or equal than 10.000' do
        work_package.story_points = '10000'
        work_package.should_not be_valid

        work_package.story_points = '10001'
        work_package.should_not be_valid
      end

      it 'disallows string values, that are not numbers' do
        work_package.story_points = 'abc'
        work_package.should_not be_valid
      end

      it 'disallows non-integers' do
        work_package.story_points = '1.3'
        work_package.should_not be_valid
      end
    end


    describe 'remaining hours' do
      it 'allows empty values' do
        work_package.remaining_hours.should be_nil
        work_package.should be_valid
      end

      it 'allows values greater than or equal to 0' do
        work_package.remaining_hours = '0'
        work_package.should be_valid

        work_package.remaining_hours = '1'
        work_package.should be_valid
      end

      it 'disallows negative values' do
        work_package.remaining_hours = '-1'
        work_package.should_not be_valid
      end

      it 'disallows string values, that are not numbers' do
        work_package.remaining_hours = 'abc'
        work_package.should_not be_valid
      end

      it 'allows non-integers' do
        work_package.remaining_hours = '1.3'
        work_package.should be_valid
      end
    end
  end

  describe 'definition of done' do
    before(:each) do
      @status_resolved = FactoryGirl.build(:status, :name => "Resolved", :is_default => false)
      @status_open = FactoryGirl.build(:status, :name => "Open", :is_default => true)
      @project = FactoryGirl.build(:project)
      @project.done_statuses = [@status_resolved]

      @work_package = FactoryGirl.build(:work_package, :project => @project,
                                        :status  => @status_open,
                                        :type => FactoryGirl.build(:type_feature))
    end

    it 'should not be done when having the initial status "open"' do
      @work_package.done?.should be_false
    end

    it 'should be done when having the status "resolved"' do
      @work_package.status = @status_resolved
      @work_package.done?.should be_true
    end

   it 'should not be done when removing done status from "resolved"' do
     @work_package.status = @status_resolved
     @project.done_statuses = Array.new
     @work_package.done?.should be_false
    end
  end

  describe "backlogs_enabled?" do
    let(:project) { FactoryGirl.build(:project) }
    let(:work_package) { FactoryGirl.build(:work_package) }

    it "should be false without a project" do
      work_package.project = nil
      work_package.should_not be_backlogs_enabled
    end

    it "should be true with a project having the backlogs module" do
      project.enabled_module_names = project.enabled_module_names + ["backlogs"]
      work_package.project = project

      work_package.should be_backlogs_enabled
    end

    it "should be false with a project not having the backlogs module" do
      work_package.project = project
      work_package.project.enabled_module_names = nil

      work_package.should_not be_backlogs_enabled
    end
  end
end
