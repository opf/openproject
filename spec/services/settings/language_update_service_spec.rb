# frozen_string_literal: true

# -- copyright
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
# ++
#

require "spec_helper"

RSpec.describe Settings::LanguageUpdateService do
  let(:service) do
    described_class.new(user: build_stubbed(:admin))
  end
  let(:available_languages) { %w[de fr] }

  before do
    allow(service).to receive(:force_users_to_use_only_available_languages)
  end

  it "sets language of users having a non-available language to the default language" do
    service.call(available_languages:)

    expect(service)
      .to have_received(:force_users_to_use_only_available_languages)
  end

  context "when the contract is not successfully validated" do
    before do
      allow(service)
        .to receive(:validate_contract)
        .and_return(ServiceResult.failure(message: "fake error"))
    end

    it "does not change language of any users" do
      service.call(available_languages:)

      expect(service)
        .not_to have_received(:force_users_to_use_only_available_languages)
    end
  end
end
