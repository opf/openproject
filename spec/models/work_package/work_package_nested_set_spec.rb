#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

# TODO: this spec is for now targeting each WorkPackage subclass
# independently. Once only WorkPackage exist, this can safely be consolidated.
describe WorkPackage, type: :model do
  let(:project) { FactoryGirl.build(:project_with_types) }
  let(:work_package) { FactoryGirl.build(:work_package, project: project) }
  let(:work_package2) { FactoryGirl.build(:work_package, project: project) }
  let(:work_package3) { FactoryGirl.build(:work_package, project: project) }

  let(:instance) { work_package }
  let(:parent) { work_package2 }
  let(:parent2) { work_package3 }

  shared_examples_for 'root' do
    it 'should set root_id to the id of the work_package' do
      expect(instance.root_id).to eq(instance.id)
    end

    it 'should set lft to 1' do
      expect(instance.lft).to eq(1)
    end

    it 'should set rgt to 2' do
      expect(instance.rgt).to eq(2)
    end
  end

  shared_examples_for 'first child' do
    it 'should set root_id to the id of the parent work_package' do
      expect(instance.root_id).to eq(parent.id)
    end

    it 'should set lft to 2' do
      expect(instance.lft).to eq(2)
    end

    it 'should set rgt to 3' do
      expect(instance.rgt).to eq(3)
    end
  end

  describe 'instantiating a new instance' do
    it 'is considered a leaf' do
      expect(instance).to be_leaf
    end
  end

  describe 'creating a new instance without a parent' do
    before do
      instance.save!
    end

    it_should_behave_like 'root'

    it 'is considered a leaf' do
      expect(instance).to be_leaf
    end
  end

  describe 'creating a new instance with a parent' do
    before do
      parent.save!
      instance.parent = parent

      instance.save!
    end

    it_should_behave_like 'first child'

    it 'is considered a leaf' do
      expect(instance).to be_leaf
    end

    it 'the parent is not considered a leaf' do
      expect(parent.reload).to_not be_leaf
    end
  end

  describe 'an existent instance receives a parent' do
    before do
      parent.save!
      instance.save!
      instance.parent = parent
      instance.save!
    end

    it_should_behave_like 'first child'
  end

  describe 'an existent instance becomes a root' do
    before do
      parent.save!
      instance.parent = parent
      instance.save!
      instance.parent_id = nil
      instance.save!
    end

    it_should_behave_like 'root'

    it 'should set parent_id to nil' do
      expect(instance.parent_id).to eq(nil)
    end
  end

  describe 'an existent instance receives a new parent (new tree)' do
    before do
      parent.save!
      parent2.save!
      instance.parent_id = parent2.id
      instance.save!

      instance.parent = parent
      instance.save!
    end

    it_should_behave_like 'first child'

    it 'should set parent_id to new parent' do
      expect(instance.parent_id).to eq(parent.id)
    end
  end

  describe "an existent instance
            with a right sibling receives a new parent" do
    let(:other_child) { work_package3 }

    before do
      parent.save!
      instance.parent = parent
      instance.save!
      other_child.parent = parent
      other_child.save!

      instance.parent_id = nil
      instance.save!
    end

    it "former roots's root_id should be unchanged" do
      parent.reload
      expect(parent.root_id).to eq(parent.id)
    end

    it "former roots's lft should be 1" do
      parent.reload
      expect(parent.lft).to eq(1)
    end

    it "former roots's rgt should be 4" do
      parent.reload
      expect(parent.rgt).to eq(4)
    end

    it "former right siblings's root_id should be unchanged" do
      other_child.reload
      expect(other_child.root_id).to eq(parent.id)
    end

    it "former right siblings's left should be 2" do
      other_child.reload
      expect(other_child.lft).to eq(2)
    end

    it "former right siblings's rgt should be 3" do
      other_child.reload
      expect(other_child.rgt).to eq(3)
    end
  end

  describe 'an existent instance receives a new parent (same tree)' do
    before do
      parent.save!
      parent2.save!
      instance.parent_id = parent2.id
      instance.save!

      instance.parent = parent
      instance.save!
    end

    it_should_behave_like 'first child'
  end

  describe 'an existent instance with children receives a new parent (itself)' do
    let(:child) { work_package3 }

    before do
      parent.save!
      instance.parent = parent
      instance.save!
      child.parent_id = instance.id
      child.save!

      # reloading as instance's nested set attributes (lft, rgt) where
      # updated by adding child to the set
      instance.reload
      instance.parent_id = nil
      instance.save!
    end

    it "former parent's root_id should be unchanged" do
      parent.reload
      expect(parent.root_id).to eq(parent.id)
    end

    it "former parent's left should be 1" do
      parent.reload
      expect(parent.lft).to eq(1)
    end

    it "former parent's right should be 2" do
      parent.reload
      expect(parent.rgt).to eq(2)
    end

    it 'the child should have the root_id of the parent work_package' do
      child.reload
      expect(child.root_id).to eq(instance.id)
    end

    it 'the child should have a lft of 2' do
      child.reload
      expect(child.lft).to eq(2)
    end

    it 'the child should have a rgt of 3' do
      child.reload
      expect(child.rgt).to eq(3)
    end
  end
end
