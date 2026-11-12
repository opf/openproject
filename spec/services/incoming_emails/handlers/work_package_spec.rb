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

RSpec.describe IncomingEmails::Handlers::WorkPackage do
  let(:email) { instance_double(Mail::Message, attachments: [], subject: "My message") }
  let(:user) { build_stubbed(:user) }
  let(:reference) { {} }
  let(:automated_email) { false }
  let(:options) { { issue: { project: "foobar" }, allow_override: [] } }
  let(:plain_text_body) { "Test body".dup }

  subject(:handler) do
    described_class.new(email, user:, reference:, plain_text_body:, options:)
  end

  describe ".handles?" do
    context "with work package reference" do
      let(:reference) { { klass: "work_package", id: 123 } }

      it "returns true" do
        expect(described_class).to be_handles(email, reference:, automated_email:)
      end
    end

    context "with work package reference, but assuming an automated email" do
      let(:automated_email) { true }
      let(:reference) { { klass: "work_package", id: 123 } }

      it "returns false" do
        expect(described_class).not_to be_handles(email, reference:, automated_email:)
      end
    end

    context "without work package reference" do
      let(:reference) { {} }

      it "returns true for new work package creation" do
        expect(described_class).to be_handles(email, reference:, automated_email:)
      end
    end

    context "with message reference" do
      let(:reference) { { klass: "messages", id: 123 } }

      it "returns false" do
        expect(described_class).not_to be_handles(email, reference:, automated_email:)
      end
    end
  end

  describe "#process" do
    let(:service_result) { ServiceResult.success(result: build_stubbed(:work_package)) }
    let(:service_instance) { instance_double(WorkPackages::CreateService, call: service_result) }
    let(:project) { build_stubbed(:project) }

    before do
      allow(WorkPackages::CreateService).to receive(:new).and_return(service_instance)
      allow(Project).to receive(:find_by).with(identifier: "foobar").and_return(project)
    end

    it "creates a work package" do
      result = handler.process
      expect(WorkPackages::CreateService).to have_received(:new)
      expect(result).to be_a(ServiceResult)
    end

    context "when work package creation fails" do
      let(:errors) { ActiveModel::Errors.new(nil) }
      let(:service_result) { ServiceResult.failure(errors:) }

      it "returns the failed result" do
        result = handler.process
        expect(result).to be_a(ServiceResult)
        expect(result).not_to be_success
        expect(result.errors).to eq(errors)
      end
    end
  end
end
