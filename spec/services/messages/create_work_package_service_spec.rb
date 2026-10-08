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

RSpec.describe Messages::CreateWorkPackageService do
  shared_let(:type) { create(:type_task) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:forum) { create(:forum, project:) }
  shared_let(:topic) { create(:message, forum:, subject: "Release planning", content: "Opening post") }
  shared_let(:reply) { create(:message, forum:, parent: topic, content: "We should **freeze** on Friday") }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_messages view_work_packages add_work_packages edit_work_packages] })
  end

  subject(:service) { described_class.new(user:, message: reply) }

  describe "#build_work_package" do
    it "prefills the topic's subject and the message's content, verbatim", :aggregate_failures do
      work_package = service.build_work_package

      expect(work_package).to be_new_record
      expect(work_package).to have_attributes(subject: "Release planning",
                                              description: "We should **freeze** on Friday",
                                              project:,
                                              type:)
    end

    it "lets the user's edits override the prefill" do
      expect(service.build_work_package(params: { "subject" => "Freeze on Friday" }).subject).to eq("Freeze on Friday")
    end
  end

  describe "#call" do
    let(:work_package_params) { { "subject" => "Freeze on Friday", "description" => "As discussed", "type_id" => type.id } }

    it "creates the work package and journals its forum message as the cause", :aggregate_failures do
      call = service.call(work_package_params:)

      expect(call).to be_success
      expect(call.result).to be_persisted
      expect(call.result.journals.last.cause).to eq("type" => "forum_message", "message_id" => reply.id)
    end

    it "links the work package to the message it came from" do
      work_package = service.call(work_package_params:).result

      expect(reply.created_work_packages).to contain_exactly(work_package)
    end

    it "keeps the cause when the user edits the work package right after" do
      work_package = service.call(work_package_params:).result

      WorkPackages::UpdateService.new(user:, model: work_package).call(subject: "Freeze on Thursday")

      expect(work_package.journals.reload.map { it.cause["type"] }).to include("forum_message")
    end

    it "creates neither work package nor journal when the work package is invalid", :aggregate_failures do
      call = service.call(work_package_params: work_package_params.merge("subject" => ""))

      expect(call).to be_failure
      expect(WorkPackage.count).to eq(0)
      expect(Journal.where(journable_type: "WorkPackage")).to be_empty
      expect(MessageWorkPackage.count).to eq(0)
    end
  end
end
