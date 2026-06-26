# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe WorkPackages::Scopes::WithCardHash do
  shared_let(:project) { create(:project) }
  shared_let(:assignee) { create(:user) }
  shared_let(:priority) { create(:priority) }
  shared_let(:parent) { create(:work_package, project:) }
  shared_let(:work_package) do
    create(:work_package, project:, parent:, assigned_to: assignee, priority:)
  end
  shared_let(:minimal_work_package) do
    create(:work_package, project:) # no parent and no assignee
  end

  # The hash of a single work package, freshly read through the scope.
  def card_hash_for(work_package)
    WorkPackage.where(id: work_package.id).with_card_hash.first.card_hash
  end

  describe ".with_card_hash" do
    it "exposes the projected card_hash as a 32 character md5 digest" do
      expect(card_hash_for(work_package)).to match(/\A\h{32}\z/)
    end

    it "keeps work packages that have no parent or assignee (LEFT joins do not drop them)" do
      scoped = WorkPackage.where(id: minimal_work_package.id).with_card_hash.first

      expect(scoped).to eq(minimal_work_package)
      expect(scoped.card_hash).to match(/\A\h{32}\z/)
    end

    it "still loads the full work package attributes alongside the hash" do
      scoped = WorkPackage.where(id: work_package.id).with_card_hash.first

      expect(scoped.subject).to eq(work_package.subject)
      expect(scoped.parent_id).to eq(parent.id)
    end

    it "is stable when nothing relevant changes" do
      first = card_hash_for(work_package)

      expect(card_hash_for(work_package)).to eq(first)
    end

    context "when re-reading after a change" do
      def expect_hash_change(record = work_package, &)
        before = card_hash_for(record)

        travel_to(1.hour.from_now, &)

        expect(card_hash_for(record)).not_to eq(before)
      end

      it "changes when the work package itself changes" do
        expect_hash_change { work_package.update(subject: "A new subject") }
      end

      it "changes when the story points change" do
        expect_hash_change { work_package.update(story_points: 42) }
      end

      it "changes when the parent is touched (e.g. its subject is edited)" do
        expect_hash_change { parent.touch }
      end

      it "changes when the status is touched" do
        expect_hash_change { work_package.status.touch }
      end

      it "changes when the assignee is touched" do
        expect_hash_change { assignee.touch }
      end

      it "changes when the type is touched" do
        expect_hash_change { work_package.type.touch }
      end

      it "changes when the priority is touched" do
        expect_hash_change { priority.touch }
      end

      it "changes when the assignee is removed (set to nil)" do
        expect_hash_change { work_package.update(assigned_to: nil) }
      end

      it "changes when an assignee is added (nil to set)" do
        expect_hash_change(minimal_work_package) { minimal_work_package.update(assigned_to: assignee) }
      end

      it "changes when the parent is removed (set to nil)" do
        expect_hash_change { work_package.update(parent: nil) }
      end

      it "changes when a parent is added (nil to set)" do
        expect_hash_change(minimal_work_package) { minimal_work_package.update(parent:) }
      end
    end

    it "is isolated from changes to records of other work packages" do
      before = card_hash_for(work_package)

      travel_to(1.hour.from_now) { minimal_work_package.status.touch }

      # Only affects the other work package if they happen to share the status.
      expect(card_hash_for(work_package)).to eq(before) if minimal_work_package.status_id != work_package.status_id
    end
  end
end
