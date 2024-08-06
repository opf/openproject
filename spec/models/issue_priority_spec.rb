#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++
require "spec_helper"

RSpec.describe IssuePriority do
  shared_let(:priority) { create(:priority) }
  shared_let(:default_priority) { create(:default_priority) }

  let(:stubbed_priority) { build_stubbed(:priority) }

  describe ".ancestors" do
    it "is an enumeration" do
      expect(IssuePriority.ancestors)
        .to include(Enumeration)
    end
  end

  describe "#objects_count" do
    let(:work_package1) { create(:work_package, priority:) }
    let(:work_package2) { create(:work_package) }

    it "counts the work packages having the priority" do
      expect(priority.objects_count)
        .to be 0

      work_package1
      work_package2

      # will not count the other work package
      expect(priority.objects_count)
        .to be 1
    end
  end

  describe "#option_name" do
    it "is a symbol" do
      expect(stubbed_priority.option_name)
        .to be :enumeration_work_package_priorities
    end
  end

  describe "#cache_key" do
    it "updates when the updated_at field changes" do
      old_cache_key = stubbed_priority.cache_key

      stubbed_priority.updated_at = Time.now

      expect(stubbed_priority.cache_key)
        .not_to eql old_cache_key
    end
  end

  describe "#transer_to" do
    let(:new_priority) { create(:priority) }
    let(:work_package1) { create(:work_package, priority:) }
    let(:work_package2) { create(:work_package) }
    let(:work_package3) { create(:work_package, priority: new_priority) }

    it "moves all work_packages to the designated priority" do
      work_package1
      work_package2
      work_package3

      priority.transfer_relations(new_priority)

      expect(new_priority.work_packages.reload)
        .to contain_exactly(work_package3, work_package1)
    end
  end

  describe "#in_use?" do
    context "with a work package that uses the priority" do
      let!(:work_package) { create(:work_package, priority:) }

      it "is true" do
        expect(priority)
          .to be_in_use
      end
    end

    context "without a work package that uses the priority" do
      it "is false" do
        expect(priority)
          .not_to be_in_use
      end
    end
  end

  describe ".default" do
    it "returns the default priority" do
      expect(described_class.default)
        .to eq default_priority
    end

    it "changes if a new default priority is created" do
      new_default = described_class.create(name: "New default", is_default: true)

      expect(described_class.default)
        .to eq new_default
    end

    it "does not change if a new non default priority is created" do
      described_class.create(name: "New default", is_default: false)

      expect(described_class.default)
        .to eq default_priority
    end

    it "is nil if the default priority looses the default flag" do
      default_priority.update(is_default: false)

      expect(described_class.default)
        .to be_nil
    end
  end

  describe "#default?" do
    it "is true for a default priority" do
      expect(default_priority)
        .to be_is_default
    end

    it "is false for a non default priority" do
      expect(priority)
        .not_to be_is_default
    end

    it "changes if a new default priority is created" do
      described_class.create(name: "New default", is_default: true)

      expect(default_priority.reload)
        .not_to be_is_default
    end

    it "changes if an existing priority is assigned default" do
      new_default_priority = create(:priority)
      new_default_priority.update(is_default: true)

      expect(default_priority.reload)
        .not_to be_is_default
    end
  end

  describe ".destroy" do
    let!(:work_package) { create(:work_package, priority:) }

    context "with reassign" do
      it "reassigns the work packages" do
        priority.destroy(default_priority)

        expect(WorkPackage.where(priority: default_priority))
          .to eq [work_package]
      end
    end

    context "without reassign" do
      it "raises an error as it is in use" do
        expect { priority.destroy }
          .to raise_error RuntimeError
      end
    end
  end
end
