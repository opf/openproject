# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackage do
  let(:work_package) { create(:work_package) }
  let(:user) { create(:user) }

  describe "#cleanup_associated_before_destructing_if_required with multiple registered associations" do
    let(:original_subject) { work_package.subject }
    let(:succeeding_cleanup) do
      ->(work_packages, _user, _to_do) do
        described_class.where(id: Array(work_packages).map(&:id)).update_all(subject: "cleaned up")
        true
      end
    end
    let(:failing_cleanup) { ->(*) { false } }
    let(:registrations) do
      cleanups.map do |cleanup|
        WorkPackage::AskBeforeDestruction::DestructionRegistration.new(Class.new, ->(_) { true }, cleanup)
      end
    end

    let(:action) { described_class.cleanup_associated_before_destructing_if_required([work_package], user, action: "destroy") }

    before do
      original_subject

      allow(described_class)
        .to receive(:registered_associated_to_ask_before_destruction)
        .and_return(registrations)
    end

    context "when all cleanups succeed" do
      let(:cleanups) { [succeeding_cleanup, succeeding_cleanup] }

      it "returns true" do
        expect(action).to be_truthy
      end

      it "keeps the changes of the cleanups" do
        action

        expect(work_package.reload.subject).to eq("cleaned up")
      end
    end

    context "when the last cleanup fails" do
      let(:cleanups) { [succeeding_cleanup, failing_cleanup] }

      it "returns false" do
        expect(action).to be_falsey
      end

      it "rolls back the changes of the other cleanups" do
        action

        expect(work_package.reload.subject).to eq(original_subject)
      end
    end

    context "when an earlier cleanup fails" do
      let(:cleanups) { [failing_cleanup, succeeding_cleanup] }

      it "returns false" do
        expect(action).to be_falsey
      end

      it "rolls back the changes of the other cleanups" do
        action

        expect(work_package.reload.subject).to eq(original_subject)
      end
    end
  end
end
