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

RSpec.describe Wikis::Adapters::Providers::XWiki::Validators::ConfigurationValidator do
  subject(:validation_result) { described_class.new(provider).call }

  let(:provider) { create(:xwiki_provider, :with_oauth_configured) }

  it "returns a ResultGroup" do
    expect(validation_result).to be_a(HealthReport::ResultGroup)
    expect(validation_result).to be_success
  end

  context "when the provider is not configured completely" do
    before do
      allow(provider).to receive(:configured?).and_return(false)
    end

    it { is_expected.to be_failure }

    it "indicates that the provider is not configured" do
      expect(validation_result[:provider_configured].code).to eq(:not_configured)
    end
  end
end
