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
require_module_spec_helper

RSpec.describe ITSM::Adapters::Queries::RawEmail do
  include_context "with a connected IMAP session"

  subject(:result) { described_class.call(session:, uid: 7) }

  it "returns the raw email without marking it as read" do
    allow(imap).to receive(:uid_fetch)
      .with(7, "BODY.PEEK[]")
      .and_return([Net::IMAP::FetchData.new(1, { "BODY[]" => "raw email" })])

    expect(result).to eq(Dry::Monads::Success("raw email"))
  end

  it "returns nothing when the email is gone" do
    allow(imap).to receive(:uid_fetch).and_return(nil)

    expect(result).to eq(Dry::Monads::Success(nil))
  end
end
