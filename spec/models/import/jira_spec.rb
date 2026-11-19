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

RSpec.describe Import::Jira do
  subject(:jira) { build(:jira, url:) }

  describe "URL" do
    context "with spaces around it" do
      let(:url) { " https://jira.example.com " }

      it "strips them" do
        expect(jira.url).to eq("https://jira.example.com")
        expect(jira).to be_valid
      end
    end

    ["http://jira.example.com", "https://jira.example.com/jira"].each do |valid_url|
      context "with #{valid_url}" do
        let(:url) { valid_url }

        it { is_expected.to be_http_url }
        it { is_expected.to be_valid }
      end
    end

    ["ftp://jira.example.com", "https://", "not a url"].each do |invalid_url|
      context "with #{invalid_url.inspect}" do
        let(:url) { invalid_url }

        it { is_expected.not_to be_http_url }

        it "is invalid with a translated message" do
          expect(jira).not_to be_valid
          expect(jira.errors.full_messages_for(:url)).to contain_exactly("Jira instance URL is not a valid URL.")
        end
      end
    end
  end
end
