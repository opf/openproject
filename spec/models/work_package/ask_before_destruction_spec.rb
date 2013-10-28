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

describe WorkPackage do
  let(:work_package) { FactoryGirl.create(:work_package, :project => project,
                                                         :status => status) }
  let(:work_package2) { FactoryGirl.create(:work_package, :project => project2,
                                                          :status => status) }
  let(:user) { FactoryGirl.create(:user) }

  let(:type) { FactoryGirl.create(:type_standard) }
  let(:project) { FactoryGirl.create(:project, types: [type]) }
  let(:project2) { FactoryGirl.create(:project, types: [type]) }
  let(:role) { FactoryGirl.create(:role) }
  let(:role2) { FactoryGirl.create(:role) }
  let(:member) { FactoryGirl.create(:member, :principal => user,
                                             :roles => [role]) }
  let(:member2) { FactoryGirl.create(:member, :principal => user,
                                              :roles => [role2],
                                              :project => work_package2.project) }
  let(:status) { FactoryGirl.create(:status) }
  let(:priority) { FactoryGirl.create(:priority) }
  let(:cost_type) { FactoryGirl.create(:cost_type) }
  let(:cost_entry) { FactoryGirl.build(:cost_entry, :work_package => work_package,
                                                    :project => work_package.project,
                                                    :cost_type => cost_type) }
  let(:cost_entry2) { FactoryGirl.build(:cost_entry, :work_package => work_package2,
                                                     :project => work_package2.project,
                                                     :cost_type => cost_type) }

  describe :cleanup_action_required_before_destructing? do
    describe 'w/ the work package having a cost entry' do
      before do
        work_package
        cost_entry.save!
      end

      it "should be true" do
        WorkPackage.cleanup_action_required_before_destructing?(work_package).should be_true
      end
    end

    describe 'w/ two work packages having a cost entry' do
      before do
        work_package
        cost_entry.save!
        cost_entry2.save!
      end

      it "should be true" do
        WorkPackage.cleanup_action_required_before_destructing?([work_package, work_package2]).should be_true
      end
    end

    describe 'w/o the work package having a cost entry' do
      before do
        work_package
      end

      it "should be false" do
        WorkPackage.cleanup_action_required_before_destructing?(work_package).should be_false
      end
    end
  end

  describe :associated_classes_to_address_before_destructing? do
    describe 'w/ the work package having a cost entry' do
      before do
        work_package
        cost_entry.save!
      end

      it "should be have 'CostEntry' as class to address" do
        WorkPackage.associated_classes_to_address_before_destruction_of(work_package).should == [CostEntry]
      end
    end

    describe 'w/o the work package having a cost entry' do
      before do
        work_package
      end

      it "should be empty" do
        WorkPackage.associated_classes_to_address_before_destruction_of(work_package).should be_empty
      end
    end
  end

  describe :cleanup_associated_before_destructing_if_required do
    before do
      work_package.save!

      cost_entry.save!
    end

    describe 'w/o a cleanup beeing necessary' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, :action => 'reassign') }

      before do
        cost_entry.destroy
      end

      it 'should return true' do
        action.should be_true
      end
    end

    describe 'w/ "destroy" as action' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, :action => 'destroy') }

      it 'should return true' do
        action.should be_true
      end

      it 'should not touch the cost_entry' do
        action

        cost_entry.reload
        cost_entry.work_package_id.should == work_package.id
      end
    end

    describe 'w/o an action' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user) }

      it 'should return true' do
        action.should be_true
      end

      it 'should not touch the cost_entry' do
        action

        cost_entry.reload
        cost_entry.work_package_id.should == work_package.id
      end
    end

    describe 'w/ "nullify" as action' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, :action => 'nullify') }

      it 'should return false' do
        action.should be_false
      end

      it 'should not alter the work_package_id of all cost entries' do
        action

        cost_entry.reload
        cost_entry.work_package_id.should == work_package.id
      end

      it 'should set an error on work packages' do
        action

        work_package.errors.get(:base).should == [I18n.t(:'activerecord.errors.models.work_package.nullify_is_not_valid_for_cost_entries')]
      end
    end

    describe 'w/ "reassign" as action
              w/ reassigning to a valid work_package' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, :action => 'reassign', :reassign_to_id => work_package2.id) }

      before do
        work_package2.save!
        role2.permissions << :edit_cost_entries
        role2.save!
        member2.save!
      end

      it 'should return true' do
        action.should be_true
      end

      it 'should set the work_package_id of all cost entries to the new work package' do
        action

        cost_entry.reload
        cost_entry.work_package_id.should == work_package2.id
      end

      it "should set the project_id of all cost entries to the new work package's project" do
        action

        cost_entry.reload
        cost_entry.project_id.should == work_package2.project_id
      end
    end

    describe 'w/ "reassign" as action
              w/ reassigning to a work_package the user is not allowed to see' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, :action => 'reassign', :reassign_to_id => work_package2.id) }

      before do
        work_package2.save!
      end

      it 'should return true' do
        action.should be_false
      end

      it 'should not alter the work_package_id of all cost entries' do
        action

        cost_entry.reload
        cost_entry.work_package_id.should == work_package.id
      end
    end

    describe 'w/ "reassign" as action
              w/ reassigning to a non existing work package' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, :action => 'reassign', :reassign_to_id => 0) }

      it 'should return true' do
        action.should be_false
      end

      it 'should not alter the work_package_id of all cost entries' do
        action

        cost_entry.reload
        cost_entry.work_package_id.should == work_package.id
      end
    end

    describe 'w/ "reassign" as action
              w/o providing a reassignment id' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, :action => 'reassign') }

      it 'should return true' do
        action.should be_false
      end

      it 'should not alter the work_package_id of all cost entries' do
        action

        cost_entry.reload
        cost_entry.work_package_id.should == work_package.id
      end
    end

    describe 'w/ an invalid option' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, :action => 'bogus') }

      it 'should return false' do
        action.should be_false
      end
    end

    describe 'w/ nil as invalid option' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, nil) }

      it 'should return false' do
        action.should be_false
      end
    end
  end
end

