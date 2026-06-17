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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackages::ActivitiesTab::CommentService do
  let(:work_package) { build_stubbed(:work_package) }
  let(:user) { build_stubbed(:user) }
  let(:add_service) { instance_double(AddWorkPackageNoteService, call: nil) }
  let(:update_service) { instance_double(Journals::UpdateService, call: nil) }
  let(:sanitizer) { WorkPackages::ActivitiesTab::InternalCommentMentionsSanitizer }

  def service(params)
    described_class.new(work_package:, user:, params: ActionController::Parameters.new(params))
  end

  before do
    allow(AddWorkPackageNoteService).to receive(:new).with(user:, work_package:).and_return(add_service)
    allow(Journals::UpdateService).to receive(:new).and_return(update_service)
    allow(sanitizer).to receive(:sanitize).and_return("sanitised")
  end

  describe "#add" do
    it "writes the raw notes for a public comment and notifies by default" do
      service(journal: { notes: "hi", internal: "false" }).add

      expect(add_service).to have_received(:call).with("hi", send_notifications: true, internal: false)
      expect(sanitizer).not_to have_received(:sanitize)
    end

    it "sanitises the notes for an internal comment" do
      service(journal: { notes: "raw", internal: "true" }).add

      expect(sanitizer).to have_received(:sanitize).with(work_package, "raw")
      expect(add_service).to have_received(:call).with("sanitised", send_notifications: true, internal: true)
    end

    it "honours an explicit notify=false flag" do
      service(journal: { notes: "hi", internal: "false" }, notify: "false").add

      expect(add_service).to have_received(:call).with("hi", send_notifications: false, internal: false)
    end
  end

  describe "#update" do
    let(:public_journal) { build_stubbed(:work_package_journal, internal: false) }
    let(:internal_journal) { build_stubbed(:work_package_journal, internal: true) }

    it "writes the raw notes when the comment is public" do
      service(journal: { notes: "edit" }).update(public_journal)

      expect(Journals::UpdateService).to have_received(:new).with(model: public_journal, user:)
      expect(update_service).to have_received(:call).with(notes: "edit")
      expect(sanitizer).not_to have_received(:sanitize)
    end

    it "sanitises the notes when the comment is internal" do
      service(journal: { notes: "raw" }).update(internal_journal)

      expect(update_service).to have_received(:call).with(notes: "sanitised")
    end
  end

  describe "#sanitized_notes" do
    it "passes the raw notes through the mentions sanitiser" do
      expect(service(journal: { notes: "raw" }).sanitized_notes).to eq("sanitised")
      expect(sanitizer).to have_received(:sanitize).with(work_package, "raw")
    end
  end
end
