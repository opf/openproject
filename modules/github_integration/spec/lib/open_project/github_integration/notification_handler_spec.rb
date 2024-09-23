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

require File.expand_path("../../../spec_helper", __dir__)

RSpec.describe OpenProject::GithubIntegration::NotificationHandler do
  let(:payload) { {} }

  shared_examples_for "a notification handler" do
    let(:handler) { instance_double(handler_class) }

    before do
      allow(handler_class).to receive(:new).and_return(handler)
      allow(handler).to receive(:process).and_return(nil)
    end

    it "forwards the payload to a new handler instance" do
      process
      expect(handler).to have_received(:process).with(payload)
    end

    context "when the handler throws an error" do
      before do
        allow(handler).to receive(:process).and_raise("oops")
        allow(Rails.logger).to receive(:error)
      end

      it "logs the error message" do
        expect { process }.to raise_error("oops")
        expect(Rails.logger).to have_received(:error)
      end
    end
  end

  describe ".check_run" do
    subject(:process) { described_class.check_run(payload) }

    let(:handler_class) { described_class::CheckRun }

    it_behaves_like "a notification handler"
  end

  describe ".issue_comment" do
    subject(:process) { described_class.issue_comment(payload) }

    let(:handler_class) { described_class::IssueComment }

    it_behaves_like "a notification handler"
  end

  describe ".pull_request" do
    subject(:process) { described_class.pull_request(payload) }

    let(:handler_class) { described_class::PullRequest }

    it_behaves_like "a notification handler"
  end
end
