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

RSpec.describe IncomingEmails::Handlers::MessageReply do
  let(:email) { instance_double(Mail::Message, attachments: [], subject: "Email subject") }
  let(:user) { build_stubbed(:user) }
  let(:reference) { {} }
  let(:automated_email) { false }
  let(:options) { {} }
  let(:plain_text_body) { "Test body" }

  subject(:handler) do
    described_class.new(email, user:, reference:, plain_text_body:, options:)
  end

  describe ".handles?" do
    context "with message reference" do
      let(:reference) { { klass: "message", id: 123 } }

      it "returns true" do
        expect(described_class).to be_handles(email, reference:, automated_email:)
      end
    end

    context "without message reference" do
      let(:reference) { {} }

      it "returns false" do
        expect(described_class).not_to be_handles(email, reference:, automated_email:)
      end
    end

    context "with work package reference" do
      let(:reference) { { klass: "work_packages", id: 123 } }

      it "returns false" do
        expect(described_class).not_to be_handles(email, reference:, automated_email:)
      end
    end
  end

  describe "#process" do
    let(:project) { create(:project) }
    let(:forum) { create(:forum, project:) }
    let(:message) { create(:message, forum:) }
    let(:reference) { { klass: "messages", id: message.id } }

    before do
      allow(Message).to receive(:find_by).with(id: message.id).and_return(message)
    end

    context "when not allowed to create a message" do
      it "raises an exception" do
        expect { handler.process }.to raise_error(IncomingEmails::UnauthorizedAction)
      end
    end

    context "when allowed to create a message" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:add_messages, project:)
        end
      end

      it "creates a reply message" do
        call = handler.process
        expect(call).to be_a(ServiceResult)

        message = call.result
        expect(message).to be_a(Message)
      end
    end

    context "when parent message is not found" do
      before do
        allow(Message).to receive(:find_by).and_return(nil)
      end

      it "returns nil" do
        result = handler.process
        expect(result).to be_nil
      end
    end
  end
end
