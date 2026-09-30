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

RSpec.describe IncomingEmails::MailHandler, "integration", type: :service do
  # Integration tests to ensure backwards compatibility after refactoring

  shared_let(:project) { create(:valid_project, identifier: "test-project") }
  shared_let(:user) { create(:user, mail: "test@example.com") }
  shared_let(:priority) { create(:priority_low, is_default: true) }

  describe "MailHandler.receive" do
    let(:raw_email) do
      <<~EMAIL
        From: test@example.com
        To: project@example.com
        Subject: Test Work Package
        Content-Type: text/plain

        Project: #{project.identifier}

        This is a test work package created via email.
      EMAIL
    end

    it "still processes emails through the old API" do
      result = described_class.receive(raw_email)

      expect(result).to be_a(WorkPackage)
      expect(result.subject).to eq("Test Work Package")
      expect(result.project).to eq(project)
      expect(result.author).to eq(user)
      expect(result.description).to include("This is a test work package created via email.")
    end

    it "handles options parameter" do
      result = described_class.receive(raw_email, { allow_override: "priority" })

      expect(result).to be_a(WorkPackage)
      expect(result.project).to eq(project)
    end

    context "with unknown user" do
      let(:unknown_email) do
        <<~EMAIL
          From: unknown@example.com
          To: project@example.com
          Subject: Test from unknown
          Content-Type: text/plain

          Project: #{project.identifier}

          This is from an unknown user.
        EMAIL
      end

      it "handles unknown_user option, but does not skip permission checks" do
        result = described_class.receive(unknown_email, { unknown_user: "accept" })
        expect(result).to be_a(WorkPackage)
        expect(result.project).to eq(project)

        expect(result.errors.symbols_for(:base)).to contain_exactly(:error_unauthorized)
      end
    end

    context "with auto-reply headers" do
      let(:auto_reply_email) do
        <<~EMAIL
          From: test@example.com
          To: project@example.com
          Subject: Test Auto Reply
          X-Auto-Response-Suppress: OOF
          Content-Type: text/plain

          Project: #{project.identifier}

          This is an auto-reply.
        EMAIL
      end

      it "ignores auto-reply emails" do
        result = described_class.receive(auto_reply_email)

        expect(result).to be_nil
      end
    end

    context "with work package reference" do
      let!(:work_package) { create(:work_package, project:) }
      let(:options) { {} }
      let(:reply_email) do
        <<~EMAIL
          From: test@example.com
          To: project@example.com
          Subject: Re: #{work_package.subject}
          References: <op.work_package-#{work_package.id}@example.com>
          Content-Type: text/plain

          This is a reply to the work package.
        EMAIL
      end

      subject { described_class.receive(reply_email, options) }

      shared_examples "successful work package reply" do
        it "processes work package replies" do
          expect { subject }.to change(Journal, :count).by(1)

          expect(subject).to be_a(Journal)
          expect(subject.journable).to eq(work_package)
          expect(subject.notes).to include("This is a reply to the work package.")
        end
      end

      context "with permission" do
        let!(:role) { create(:project_role, permissions: %i[view_work_packages add_work_package_comments]) }
        let!(:member) { create(:member, project:, user:, roles: [role]) }

        it_behaves_like "successful work package reply"
      end

      context "without permission" do
        it "fails to process" do
          expect { subject }.not_to change(Journal, :count)
        end
      end

      context "without permission, but no_permission_check set" do
        let(:options) do
          { no_permission_check: true }
        end

        it_behaves_like "successful work package reply"
      end
    end

    context "with message reference" do
      let(:options) { {} }
      let!(:message) { create(:message, forum: create(:forum, project:)) }
      let(:message_reply_email) do
        <<~EMAIL
          From: test@example.com
          To: project@example.com
          Subject: Re: #{message.subject}
          References: <op.message-#{message.id}@example.com>
          Content-Type: text/plain

          This is a reply to the message.
        EMAIL
      end

      subject { described_class.receive(message_reply_email, options) }

      shared_examples "successful message reply" do
        it "processes message replies" do
          expect { subject }.to change(Message, :count).by(1)

          expect(subject).to be_a(Message)
          expect(subject.parent).to eq(message)
          expect(subject.content).to include("This is a reply to the message.")
        end
      end

      context "with permission" do
        let!(:role) { create(:project_role, permissions: [:add_messages]) }
        let!(:member) { create(:member, project:, user:, roles: [role]) }

        it_behaves_like "successful message reply"
      end

      context "without permission" do
        it "fails to process" do
          expect { subject }.not_to change(Message, :count)
          expect(subject).to be_nil
        end
      end

      context "without permission, but no_permission_check set" do
        let(:options) do
          { no_permission_check: true }
        end

        it_behaves_like "successful message reply"
      end
    end
  end

  describe "Error handling" do
    let(:invalid_email) do
      <<~EMAIL
        From: test@example.com
        To: project@example.com
        Subject: Invalid Email
        Content-Type: text/plain

        Project: nonexistent-project

        This references a nonexistent project.
      EMAIL
    end

    it "handles errors gracefully" do
      expect { described_class.receive(invalid_email) }.not_to raise_error
    end
  end

  describe "Handler registration" do
    let(:custom_handler) do
      Class.new(IncomingEmails::Handlers::Base) do
        def self.handles?(email, **)
          email.subject&.include?("CUSTOM")
        end

        def process
          ServiceResult.success(message: "Custom handler processed", result: "foo result")
        end
      end
    end

    let(:custom_email) do
      <<~EMAIL
        From: test@example.com
        To: project@example.com
        Subject: CUSTOM Test Email
        Content-Type: text/plain

        This should be handled by the custom handler.
      EMAIL
    end

    it "allows custom handlers to be registered" do
      IncomingEmails::DispatchService.register_handler(custom_handler)

      result = described_class.receive(custom_email.dup)

      expect(result).to eq("foo result")
    end
  end
end
