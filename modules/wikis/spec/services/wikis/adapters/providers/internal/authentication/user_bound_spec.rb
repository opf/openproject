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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Wikis::Adapters::Providers::Internal::Authentication::UserBound do
  let(:provider) { build_stubbed(:internal_wiki_provider) }
  let(:user) { build_stubbed(:user) }

  subject(:user_bound) { described_class.new(model: provider) }

  it "is registered" do
    expect(Wikis::Adapters::Registry.resolve("internal.authentication.user_bound")).to eq(described_class)
  end

  describe "#call" do
    it "returns a Success with an internal strategy carrying the user and provider" do
      result = user_bound.call(user)
      expect(result).to be_success
      expect(result.value!).to have_attributes(key: :internal, user:, provider:)
    end
  end
end
