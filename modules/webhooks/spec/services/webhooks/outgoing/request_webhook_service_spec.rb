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

RSpec.describe Webhooks::Outgoing::RequestWebhookService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:instance) { described_class.new(webhook, event_name: :created, current_user: user) }

  shared_let(:webhook) { create(:webhook, all_projects: true, url: "https://example.net/test/42", secret: nil) }

  subject { instance.call!(body: "body", headers: {}) }

  describe "#call!" do
    context "when request_url fails with SSL errors" do
      it "still logs the exception" do
        allow(Faraday)
          .to receive(:post)
          .with(webhook.url, *any_args)
          .and_raise(Faraday::SSLError, "SSL error")

        expect { subject }
          .to change(Webhooks::Log, :count).by(1)
      end
    end
  end
end
