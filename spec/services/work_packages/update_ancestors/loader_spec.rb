#  OpenProject is an open source project management software.
#  Copyright (C) 2010-2022 the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

require 'spec_helper'

RSpec.describe WorkPackages::UpdateAncestors::Loader, type: :model do
  shared_let(:grandgrandparent) do
    create(:work_package)
  end
  shared_let(:grandparent_sibling) do
    create(:work_package,
           parent: grandgrandparent)
  end
  shared_let(:grandparent) do
    create(:work_package,
           parent: grandgrandparent)
  end
  shared_let(:parent) do
    create(:work_package,
           parent: grandparent)
  end
  shared_let(:sibling) do
    create(:work_package,
           parent:)
  end
  shared_let(:work_package) do
    create(:work_package,
           parent:)
  end
  shared_let(:child) do
    create(:work_package,
           parent: work_package)
  end

  let(:include_former_ancestors) { true }

  let(:instance) do
    described_class
      .new(work_package, include_former_ancestors)
  end

  describe '#select' do
    subject do
      work_package.parent = new_parent
      work_package.save!

      instance
    end

    context 'when switching the hierarchy' do
      let!(:new_grandgrandparent) do
        create(:work_package,
               subject: 'new grandgrandparent')
      end
      let!(:new_grandparent) do
        create(:work_package,
               parent: new_grandgrandparent,
               subject: 'new grandparent')
      end
      let!(:new_parent) do
        create(:work_package,
               subject: 'new parent',
               parent: new_grandparent)
      end
      let!(:new_sibling) do
        create(:work_package,
               subject: 'new sibling',
               parent: new_parent)
      end

      it 'iterates over both current and former ancestors' do
        expect(subject.select { |ancestor| ancestor })
          .to eql [new_parent, new_grandparent, new_grandgrandparent, parent, grandparent, grandgrandparent]
      end
    end

    context 'when switching the hierarchy and not including the former ancestors' do
      let!(:new_grandgrandparent) do
        create(:work_package,
               subject: 'new grandgrandparent')
      end
      let!(:new_grandparent) do
        create(:work_package,
               parent: new_grandgrandparent,
               subject: 'new grandparent')
      end
      let!(:new_parent) do
        create(:work_package,
               subject: 'new parent',
               parent: new_grandparent)
      end
      let!(:new_sibling) do
        create(:work_package,
               subject: 'new sibling',
               parent: new_parent)
      end

      let(:include_former_ancestors) { false }

      it 'iterates over the current ancestors' do
        expect(subject.select { |ancestor| ancestor })
          .to eql [new_parent, new_grandparent, new_grandgrandparent]
      end
    end

    context 'when removing the parent' do
      let(:new_parent) { nil }

      it 'iterates over the former ancestors' do
        expect(subject.select { |ancestor| ancestor })
          .to eql [parent, grandparent, grandgrandparent]
      end
    end

    context 'when removing the parent and not including the former ancestors' do
      let(:new_parent) { nil }
      let(:include_former_ancestors) { false }

      it 'loads nothing' do
        expect(subject.select { |ancestor| ancestor })
          .to be_empty
      end
    end

    context 'when changing the parent within the same hierarchy upwards' do
      let(:new_parent) { grandgrandparent }

      it 'iterates over the former ancestors' do
        expect(subject.select { |ancestor| ancestor })
          .to eql [parent, grandparent, grandgrandparent]
      end
    end

    context 'when changing the parent within the same hierarchy upwards and not loading former ancestors' do
      let(:new_parent) { grandgrandparent }
      let(:include_former_ancestors) { false }

      it 'iterates over the current ancestors' do
        expect(subject.select { |ancestor| ancestor })
          .to eql [grandgrandparent]
      end
    end

    context 'when changing the parent within the same hierarchy sideways' do
      let(:new_parent) { sibling }

      it 'iterates over the current ancestors' do
        expect(subject.select { |ancestor| ancestor })
          .to eql [sibling, parent, grandparent, grandgrandparent]
      end
    end

    context 'when changing the parent within the same hierarchy sideways and not loading former ancestors' do
      let(:new_parent) { sibling }
      let(:include_former_ancestors) { false }

      it 'iterates over the current ancestors' do
        expect(subject.select { |ancestor| ancestor })
          .to eql [sibling, parent, grandparent, grandgrandparent]
      end
    end

    context 'when changing the parent within the same hierarchy sideways but to a different level' do
      let(:new_parent) { grandparent_sibling }

      it 'iterates over the former and the current ancestors' do
        expect(subject.select { |ancestor| ancestor })
          .to eql [grandparent_sibling, parent, grandparent, grandgrandparent]
      end
    end

    context 'when changing the parent within the same hierarchy sideways but to a different level and not loading ancestors' do
      let(:new_parent) { grandparent_sibling }
      let(:include_former_ancestors) { false }

      it 'iterates over the former and the current ancestors' do
        expect(subject.select { |ancestor| ancestor })
          .to eql [grandparent_sibling, grandgrandparent]
      end
    end
  end

  describe '#descendants_of' do
    def descendants_of_hash(hashed_work_package)
      { "estimated_hours" => nil,
        "id" => hashed_work_package.id,
        "ignore_non_working_days" => false,
        "parent_id" => hashed_work_package.parent_id,
        "remaining_hours" => nil,
        "schedule_manually" => false }
    end

    context 'for the work_package' do
      it 'is its child (as a hash)' do
        expect(instance.descendants_of(work_package))
          .to match_array([descendants_of_hash(child)])
      end
    end

    context 'for the parent' do
      it 'is the work package, its child (as a hash) and its sibling (as a hash)' do
        expect(instance.descendants_of(parent))
          .to match_array([descendants_of_hash(child),
                           work_package,
                           descendants_of_hash(sibling)])
      end
    end

    context 'for the grandparent' do
      it 'is the parent, the work package, its child (as a hash) and its sibling (as a hash)' do
        expect(instance.descendants_of(grandparent))
          .to match_array([parent,
                           work_package,
                           descendants_of_hash(child),
                           descendants_of_hash(sibling)])
      end
    end

    context 'for the grandgrandparent (the root)' do
      it 'is the complete tree, partly as a hash and partly as the preloaded work packages' do
        expect(instance.descendants_of(grandgrandparent))
          .to match_array([descendants_of_hash(grandparent_sibling),
                           grandparent,
                           parent,
                           work_package,
                           descendants_of_hash(child),
                           descendants_of_hash(sibling)])
      end
    end
  end

  describe '#children_of' do
    def children_of_hash(hashed_work_package)
      { "estimated_hours" => nil,
        "id" => hashed_work_package.id,
        "ignore_non_working_days" => false,
        "parent_id" => hashed_work_package.parent_id,
        "remaining_hours" => nil,
        "schedule_manually" => false }
    end

    context 'for the work_package' do
      it 'is its child (as a hash)' do
        expect(instance.children_of(work_package))
          .to match_array([children_of_hash(child)])
      end
    end

    context 'for the parent' do
      it 'is the work package and its sibling (as a hash)' do
        expect(instance.children_of(parent))
          .to match_array([work_package,
                           children_of_hash(sibling)])
      end
    end

    context 'for the grandparent' do
      it 'is the parent' do
        expect(instance.children_of(grandparent))
          .to match_array([parent])
      end
    end

    context 'for the grandgrandparent' do
      it 'is the grandparent and its sibling (as a hash)' do
        expect(instance.children_of(grandgrandparent))
          .to match_array([children_of_hash(grandparent_sibling),
                           grandparent])
      end
    end
  end
end
