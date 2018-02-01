#-- encoding: UTF-8

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

describe Relation, 'hierarchy_paths', type: :model do
  let(:parent) { FactoryGirl.create(:work_package) }
  let(:child) { FactoryGirl.create(:work_package) }
  let(:grand_parent) do
    wp = FactoryGirl.create(:work_package)
    parent.parent = wp
    parent.save!
    wp
  end
  let(:grand_child) { FactoryGirl.create(:work_package, parent: child) }

  def record_for(id)
    ActiveRecord::Base.connection.select_rows <<-SQL
      SELECT work_package_id, path from hierarchy_paths WHERE work_package_id = #{id}
    SQL
  end

  def path_for(id)
    record_for(id)[0][1]
  end

  context 'on creation' do
    context 'with a relation between two work packages' do
      before do
        Relation.create relation_type: 'hierarchy', from: parent, to: child
      end

      it 'adds a hierarchy path for the child' do
        expect(record_for(child.id)).not_to be_empty
      end

      it 'has the parent_id in the path' do
        expect(path_for(child.id)).to eql parent.id.to_s
      end

      it 'has no hierarchy path for the parent' do
        expect(record_for(parent.id)).to be_empty
      end
    end

    context 'with a non hierarchy relation between two work packages' do
      before do
        Relation.create relation_type: Relation::TYPE_BLOCKS, from: parent, to: child
      end

      it 'has no hierarchy path for the child' do
        expect(record_for(child.id)).to be_empty
      end

      it 'has no hierarchy path for the parent' do
        expect(record_for(parent.id)).to be_empty
      end
    end

    context 'with a relation connecting two already existing hierarchies' do
      before do
        grand_parent
        grand_child
        Relation.create relation_type: 'hierarchy', from: parent, to: child
      end

      it 'adds a hierarchy path for the child' do
        expect(record_for(child.id)).not_to be_empty
      end

      it 'has the grand parent and the parent in the path for the child' do
        expect(path_for(child.id)).to eql "#{grand_parent.id},#{parent.id}"
      end

      it 'has grand parent, parent and child in the path for the grand_child' do
        expect(path_for(grand_child.id)).to eql "#{grand_parent.id},#{parent.id},#{child.id}"
      end
    end
  end

  context 'on deletion' do
    context 'with a simple parent-child relationship' do
      before do
        relation = Relation.create relation_type: 'hierarchy', from: parent, to: child
        relation.destroy
      end

      it 'removes the hierarchy path for the child' do
        expect(record_for(child.id)).to be_empty
      end
    end

    context 'with a relation spanning several hops' do
      before do
        grand_parent
        grand_child
        relation = Relation.create relation_type: 'hierarchy', from: parent, to: child

        relation.destroy
      end

      it 'removes the hierarchy path for the child' do
        expect(record_for(child.id)).to be_empty
      end

      it 'has the grand parent in the path for the parent' do
        expect(path_for(parent.id)).to eql grand_parent.id.to_s
      end

      it 'child in the path for the grand_child' do
        expect(path_for(grand_child.id)).to eql child.id.to_s
      end
    end

    context 'with a non hierarchy relation connecting hierarchies' do
      before do
        grand_parent
        grand_child
        relation = Relation.create relation_type: Relation::TYPE_RELATES, from: parent, to: child

        relation.destroy
      end

      it 'removes the hierarchy path for the child' do
        expect(record_for(child.id)).to be_empty
      end

      it 'has the grand parent in the path for the parent' do
        expect(path_for(parent.id)).to eql grand_parent.id.to_s
      end

      it 'child in the path for the grand_child' do
        expect(path_for(grand_child.id)).to eql child.id.to_s
      end
    end
  end

  context 'on update' do
    let(:parent_child_relation) { Relation.create relation_type: 'hierarchy', from: parent, to: child }
    let(:follows_relation) { Relation.create relation_type: 'follows', from: parent, to: child }
    let(:other_wp) { FactoryGirl.create :work_package }

    context 'on switching the type to non hierarchy' do
      before do
        parent_child_relation.relation_type = Relation::TYPE_FOLLOWS
        parent_child_relation.save
      end

      it 'removes the hierarchy_path' do
        expect(record_for(child.id)).to be_empty
      end
    end

    context 'on switching from_id' do
      before do
        parent_child_relation.from_id = other_wp.id
        parent_child_relation.save!
      end

      it 'updates the path' do
        expect(path_for(child.id)).to eql other_wp.id.to_s
      end
    end

    context 'on switching to_id' do
      before do
        grand_child
        grand_parent
        relation = Relation.create to_id: other_wp.id, from_id: parent.id, relation_type: Relation::TYPE_HIERARCHY
        relation.to_id = child.id
        relation.save!
      end

      it 'adds a path for the new child' do
        expect(path_for(child.id)).to eql "#{grand_parent.id},#{parent.id}"
      end

      it 'removes the path for the former child' do
        expect(record_for(other_wp.id)).to be_empty
      end

      it 'updates the path to the children of the new child' do
        expect(path_for(grand_child.id)).to eql "#{grand_parent.id},#{parent.id},#{child.id}"
      end
    end

    context 'on switching the type to hierarchy' do
      before do
        follows_relation.relation_type = Relation::TYPE_HIERARCHY
        follows_relation.save
      end

      it 'adds the hierarchy_path' do
        expect(record_for(child.id)).not_to be_empty
      end
    end
  end

  describe '#rebuild_hierarchy_paths!' do
    let!(:parent_child_relation) { Relation.create relation_type: 'hierarchy', from: parent, to: child }

    before do
      ActiveRecord::Base.connection.select_rows <<-SQL
        DELETE FROM hierarchy_paths
      SQL
      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO hierarchy_paths (work_package_id, path) VALUES (#{parent.id}, '123')
      SQL

      Relation.rebuild_hierarchy_paths!
    end

    it 'adds a hierarchy path for the child' do
      expect(record_for(child.id)).not_to be_empty
    end

    it 'has the parent_id in the path' do
      expect(path_for(child.id)).to eql parent.id.to_s
    end

    it 'has no hierarchy path for the parent' do
      expect(record_for(parent.id)).to be_empty
    end
  end
end
