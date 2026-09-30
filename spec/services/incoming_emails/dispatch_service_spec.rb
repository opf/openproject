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

RSpec.describe IncomingEmails::DispatchService do
  let(:email) { instance_double(Mail::Message) }
  let(:text_part) { instance_double(Mail::Part) }
  let(:body) { instance_double(Mail::Body) }
  let(:options) { {} }
  let(:service) { described_class.new(email, options:) }

  before do
    allow(body).to receive_messages(decoded: "Test body".dup)
    allow(text_part).to receive_messages(body:, charset: "UTF-8")
    allow(email).to receive_messages(text_part: text_part, header: {}, from: ["test@example.com"])
  end

  describe "#initialize" do
    it "initializes with email and options" do
      expect(service.email).to eq(email)
      expect(service.options).to include(options)
    end

    it "extracts sender email from the email" do
      expect(service.sender_email).to eq("test@example.com")
    end

    it "initializes empty logs array" do
      expect(service.logs).to eq([])
    end
  end

  describe ".handlers" do
    it "returns the default handlers" do
      expect(described_class.handlers).to include(
        IncomingEmails::Handlers::MeetingResponse,
        IncomingEmails::Handlers::MessageReply,
        IncomingEmails::Handlers::WorkPackage
      )
    end
  end

  describe ".register_handler" do
    let(:custom_handler) { class_double(IncomingEmails::Handlers::WorkPackage) }

    after do
      described_class.remove_handler(custom_handler)
    end

    it "adds handler to the beginning of the handlers list" do
      described_class.register_handler(custom_handler)
      expect(described_class.handlers).to include(custom_handler)
    end
  end

  describe "#call!" do
    let(:user) { build_stubbed(:user) }

    before do
      allow(service).to receive(:determine_actor)
      allow(service).to receive_messages(ignore_mail?: false, user: user)
      allow(service).to receive(:dispatch)
    end

    it "calls determine_actor" do
      service.call!
      expect(service).to have_received(:determine_actor)
    end

    it "calls dispatch when user is present" do
      service.call!
      expect(service).to have_received(:dispatch)
    end

    it "does not call dispatch when user is not present" do
      allow(service).to receive(:user).and_return(nil)
      service.call!
      expect(service).not_to have_received(:dispatch)
    end

    it "returns early when mail should be ignored" do
      allow(service).to receive(:ignore_mail?).and_return(true)
      service.call!
      expect(service).not_to have_received(:determine_actor)
    end
  end

  describe "#ignore_mail?" do
    it "returns false by default" do
      allow(service).to receive_messages(
        mail_from_system?: false,
        ignored_user?: false
      )

      expect(service.send(:ignore_mail?)).to be_falsey
    end
  end

  describe "#mail_from_system?" do
    context "when email is from system address" do
      before do
        allow(Setting).to receive(:mail_from).and_return("system@example.com")
        allow(email).to receive(:from).and_return(["system@example.com"])
      end

      it "returns true" do
        service = described_class.new(email, options:)
        expect(service.send(:mail_from_system?)).to be_truthy
      end
    end

    context "when email is not from system address" do
      before do
        allow(Setting).to receive(:mail_from).and_return("system@example.com")
        allow(email).to receive(:from).and_return(["user@example.com"])
      end

      it "returns false" do
        service = described_class.new(email, options:)
        expect(service.send(:mail_from_system?)).to be_falsey
      end
    end
  end

  describe "#ignored_by_header?" do
    context "with auto-response suppress header" do
      before do
        allow(email).to receive(:header).and_return({ "X-Auto-Response-Suppress" => "OOF" })
      end

      it "returns true" do
        expect(service.send(:automated_email?)).to be_truthy
      end
    end

    context "with auto-submitted header" do
      before do
        allow(email).to receive(:header).and_return({ "Auto-Submitted" => "auto-replied" })
      end

      it "returns true" do
        expect(service.send(:automated_email?)).to be_truthy
      end
    end

    context "without ignored headers" do
      before do
        allow(email).to receive(:header).and_return({})
      end

      it "returns false" do
        expect(service.send(:automated_email?)).to be_falsey
      end
    end
  end

  describe "#object_reference_from_header" do
    context "with valid reference header" do
      before do
        allow(email).to receive(:references).and_return(["<op.work_packages-123@example.com>"])
      end

      it "extracts object reference" do
        reference = service.send(:object_reference_from_header)
        expect(reference).to eq({ klass: "work_packages", id: 123 })
      end
    end

    context "without valid reference header" do
      before do
        allow(email).to receive(:references).and_return([])
      end

      it "returns empty hash" do
        reference = service.send(:object_reference_from_header)
        expect(reference).to eq({})
      end
    end
  end

  describe "#instantiate_matching_handler" do
    let(:handler_class) { class_double(IncomingEmails::Handlers::WorkPackage) }
    let(:handler_instance) { instance_double(IncomingEmails::Handlers::WorkPackage) }

    before do
      allow(service).to receive(:object_reference_from_header).and_return({})
      allow(described_class).to receive(:handlers).and_return([handler_class])
      allow(handler_class).to receive_messages(handles?: true, new: handler_instance)
    end

    it "finds and instantiates matching handler" do
      result = service.send(:instantiate_matching_handler)
      expect(result).to eq(handler_instance)
    end

    it "returns nil when no handler matches" do
      allow(handler_class).to receive(:handles?).and_return(false)
      result = service.send(:instantiate_matching_handler)
      expect(result).to be_nil
    end
  end
end
