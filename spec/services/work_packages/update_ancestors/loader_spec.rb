#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe WorkPackages::UpdateAncestors::Loader, type: :model do
  shared_let(:user) { create(:user) }
  shared_let(:project) { create(:project_with_types) }
  shared_let(:included_status) { create(:status) }
  shared_let(:excluded_status) { create(:rejected_status) }

  before_all do
    set_factory_default(:project_with_types, project)
    set_factory_default(:status, included_status)
    set_factory_default(:user, user)
  end

  shared_let(:grandgrandparent) do
    create(:work_package,
           subject: "grandgrandparent")
  end
  shared_let(:grandparent_sibling) do
    create(:work_package,
           subject: "grandparent sibling",
           parent: grandgrandparent)
  end
  shared_let(:grandparent) do
    create(:work_package,
           subject: "grandparent",
           parent: grandgrandparent)
  end
  shared_let(:parent) do
    create(:work_package,
           subject: "parent",
           parent: grandparent)
  end
  shared_let(:sibling) do
    create(:work_package,
           subject: "sibling",
           parent:)
  end
  shared_let(:work_package, refind: true) do
    create(:work_package,
           subject: "work package",
           parent:)
  end
  shared_let(:child) do
    create(:work_package,
           subject: "child",
           parent: work_package)
  end

  let(:include_former_ancestors) { true }

  let(:instance) do
    described_class
      .new(work_package, include_former_ancestors)
  end

  describe "#select" do
    subject do
      work_package.parent = new_parent
      work_package.save!

      instance
    end

    context "when switching the hierarchy" do
      let!(:new_grandgrandparent) do
        create(:work_package,
               subject: "new grandgrandparent")
      end
      let!(:new_grandparent) do
        create(:work_package,
               parent: new_grandgrandparent,
               subject: "new grandparent")
      end
      let!(:new_parent) do
        create(:work_package,
               subject: "new parent",
               parent: new_grandparent)
      end
      let!(:new_sibling) do
        create(:work_package,
               subject: "new sibling",
               parent: new_parent)
      end

      it "iterates over the initiator work package, and both its current and former ancestors" do
        expect(subject.select { |ancestor| ancestor })
          .to eq [work_package, new_parent, new_grandparent, new_grandgrandparent, parent, grandparent, grandgrandparent]
      end
    end

    context "when switching the hierarchy and not including the former ancestors" do
      let!(:new_grandgrandparent) do
        create(:work_package,
               subject: "new grandgrandparent")
      end
      let!(:new_grandparent) do
        create(:work_package,
               parent: new_grandgrandparent,
               subject: "new grandparent")
      end
      let!(:new_parent) do
        create(:work_package,
               subject: "new parent",
               parent: new_grandparent)
      end
      let!(:new_sibling) do
        create(:work_package,
               subject: "new sibling",
               parent: new_parent)
      end

      let(:include_former_ancestors) { false }

      it "iterates over the initiator work package and the current ancestors" do
        expect(subject.select { |ancestor| ancestor })
          .to eq [work_package, new_parent, new_grandparent, new_grandgrandparent]
      end
    end

    context "when destroying the initiator" do
      subject do
        work_package.destroy!

        instance
      end

      it "iterates over the former ancestors" do
        expect(subject.select { |ancestor| ancestor })
          .to eq [parent, grandparent, grandgrandparent]
      end
    end

    context "when removing the parent" do
      let(:new_parent) { nil }

      it "iterates over the initiator work package and the former ancestors" do
        expect(subject.select { |ancestor| ancestor })
          .to eq [work_package, parent, grandparent, grandgrandparent]
      end
    end

    context "when removing the parent and not including the former ancestors" do
      let(:new_parent) { nil }
      let(:include_former_ancestors) { false }

      it "loads only the initiator" do
        expect(subject.select { |ancestor| ancestor })
          .to eq [work_package]
      end
    end

    context "when changing the parent within the same hierarchy upwards" do
      let(:new_parent) { grandgrandparent }

      it "iterates over the initiator and the former ancestors" do
        expect(subject.select { |ancestor| ancestor })
          .to eq [work_package, parent, grandparent, grandgrandparent]
      end
    end

    context "when changing the parent within the same hierarchy upwards and not loading former ancestors" do
      let(:new_parent) { grandgrandparent }
      let(:include_former_ancestors) { false }

      it "iterates over the initiator and the current ancestors" do
        expect(subject.select { |ancestor| ancestor })
          .to eq [work_package, grandgrandparent]
      end
    end

    context "when changing the parent within the same hierarchy sideways" do
      let(:new_parent) { sibling }

      it "iterates over the initiator and the current ancestors" do
        expect(subject.select { |ancestor| ancestor })
          .to eq [work_package, sibling, parent, grandparent, grandgrandparent]
      end
    end

    context "when changing the parent within the same hierarchy sideways and not loading former ancestors" do
      let(:new_parent) { sibling }
      let(:include_former_ancestors) { false }

      it "iterates over the initiator and the current ancestors" do
        expect(subject.select { |ancestor| ancestor })
          .to eq [work_package, sibling, parent, grandparent, grandgrandparent]
      end
    end

    context "when changing the parent within the same hierarchy sideways but to a different level" do
      let(:new_parent) { grandparent_sibling }

      it "iterates over the initiator and its former and current ancestors" do
        expect(subject.select { |ancestor| ancestor })
          .to eq [work_package, grandparent_sibling, parent, grandparent, grandgrandparent]
      end
    end

    context "when changing the parent within the same hierarchy sideways but to a different level and not loading ancestors" do
      let(:new_parent) { grandparent_sibling }
      let(:include_former_ancestors) { false }

      it "iterates over the initiator and its former and current ancestors" do
        expect(subject.select { |ancestor| ancestor })
          .to eq [work_package, grandparent_sibling, grandgrandparent]
      end
    end
  end

  def work_package_struct(work_package)
    attribute_names = WorkPackages::UpdateAncestors::Loader::WorkPackageLikeStruct.members.map(&:to_s)
    attributes = work_package.attributes.slice(*attribute_names)
    attributes[:status_excluded_from_totals] = false
    WorkPackages::UpdateAncestors::Loader::WorkPackageLikeStruct.new(**attributes)
  end

  describe "#descendants_of" do
    context "for the work_package" do
      it "is its child (as a struct)" do
        expect(instance.descendants_of(work_package))
          .to contain_exactly(work_package_struct(child))
      end

      context "with the child having a status not being excluded from totals calculation" do
        before do
          child.update(status: included_status)
        end

        it "correctly responds true to #included_in_totals_calculation? like a WorkPackage instance" do
          child = instance.descendants_of(work_package).first
          expect(child.included_in_totals_calculation?).to be true
        end
      end

      context "with the child having a status being excluded from totals calculation" do
        before do
          child.update(status: excluded_status)
        end

        it "correctly responds false to #included_in_totals_calculation? like a WorkPackage instance" do
          child = instance.descendants_of(work_package).first
          expect(child.included_in_totals_calculation?).to be false
        end
      end
    end

    context "for the parent" do
      it "is the work package, its child (as a struct) and its sibling (as a struct)" do
        expect(instance.descendants_of(parent))
          .to contain_exactly(work_package_struct(child), work_package, work_package_struct(sibling))
      end
    end

    context "for the grandparent" do
      it "is the parent, the work package, its child (as a struct) and its sibling (as a struct)" do
        expect(instance.descendants_of(grandparent))
          .to contain_exactly(parent, work_package, work_package_struct(child), work_package_struct(sibling))
      end
    end

    context "for the grandgrandparent (the root)" do
      it "is the complete tree, partly as a struct and partly as the preloaded work packages" do
        expect(instance.descendants_of(grandgrandparent))
          .to contain_exactly(work_package_struct(grandparent_sibling), grandparent, parent, work_package,
                              work_package_struct(child), work_package_struct(sibling))
      end
    end
  end

  describe "#children_of" do
    context "for the work_package" do
      it "is its child (as a struct)" do
        expect(instance.children_of(work_package))
          .to contain_exactly(work_package_struct(child))
      end
    end

    context "for the parent" do
      it "is the work package and its sibling (as a struct)" do
        expect(instance.children_of(parent))
          .to contain_exactly(work_package, work_package_struct(sibling))
      end
    end

    context "for the grandparent" do
      it "is the parent" do
        expect(instance.children_of(grandparent))
          .to contain_exactly(parent)
      end
    end

    context "for the grandgrandparent" do
      it "is the grandparent and its sibling (as a struct)" do
        expect(instance.children_of(grandgrandparent))
          .to contain_exactly(work_package_struct(grandparent_sibling), grandparent)
      end
    end
  end
end
