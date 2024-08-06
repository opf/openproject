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

RSpec.describe OAuthClients::RedirectUriFromStateService, type: :model do
  let(:state) { "asdf123425" }
  let(:redirect_uri) { File.join(API::V3::Utilities::PathHelper::ApiV3Path::root_url, "foo/bar") }
  let(:cookies) { { "oauth_state_#{state}": { href: redirect_uri }.to_json }.with_indifferent_access }
  let(:instance) { described_class.new(state:, cookies:) }

  describe "#call" do
    subject { instance.call }

    shared_examples "failed service result" do
      it "return a failed service result" do
        expect(subject).to be_failure
      end
    end

    context "when cookie found" do
      context "when redirect_uri has same origin" do
        it "returns the redirect URL value from the cookie" do
          expect(subject).to be_success
        end
      end

      context "when redirect_uri does not share same origin" do
        let(:redirect_uri) { "https://some-other-origin.com/bla" }

        it_behaves_like "failed service result"
      end
    end

    context "when no cookie present" do
      let(:cookies) { {} }

      it_behaves_like "failed service result"
    end

    context "when no state present" do
      let(:state) { nil }

      it_behaves_like "failed service result"
    end
  end
end
