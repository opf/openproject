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

RSpec.describe WorkPackageTypes::Patterns::PatternToken do
  describe ".scan_tokens" do
    subject(:tokens) { described_class.scan_tokens(text) }

    let(:text) { "My text contains {{bare_token}} and {{token_with_format:YYYY-MM-DD}}." }

    it "recognizes all the tokens" do
      expect(tokens.size).to eq(2)
    end

    it "recognizes the bare token without a format" do
      expect(tokens.first.key).to eq(:bare_token)
      expect(tokens.first.format).to be_nil
      expect(tokens.first.pattern).to eq("{{bare_token}}")
    end

    it "recognizes the formatted token" do
      expect(tokens.last.key).to eq(:token_with_format)
      expect(tokens.last.format).to eq("YYYY-MM-DD")
      expect(tokens.last.pattern).to eq("{{token_with_format:YYYY-MM-DD}}")
    end
  end
end
