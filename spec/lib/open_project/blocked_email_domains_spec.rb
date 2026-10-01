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

RSpec.describe OpenProject::BlockedEmailDomains do
  describe ".domain_of" do
    it "returns the lower cased domain" do
      expect(described_class.domain_of("Spam@Example.COM")).to eq "example.com"
    end

    it "returns nil for values that are not addresses" do
      expect(described_class.domain_of("example.com")).to be_nil
      expect(described_class.domain_of("@example.com")).to be_nil
      expect(described_class.domain_of(nil)).to be_nil
      expect(described_class.domain_of("")).to be_nil
    end
  end

  describe ".domains" do
    context "without configuration" do
      it "is empty" do
        expect(described_class.domains).to eq []
      end
    end

    context "with a list", with_settings: { blocked_email_domains: [" Blocked.COM ", "@other.com", ".third.com", ""] } do
      it "normalizes the entries" do
        expect(described_class.domains).to eq %w[blocked.com other.com third.com]
      end
    end

    context "with a separated string", with_settings: { blocked_email_domains: "blocked.com, other.com third.com" } do
      it "splits it" do
        expect(described_class.domains).to eq %w[blocked.com other.com third.com]
      end
    end
  end

  describe ".blocked?", with_settings: { blocked_email_domains: ["blocked.com"] } do
    it "blocks the configured domain" do
      expect(described_class).to be_blocked("user@blocked.com")
    end

    it "blocks it regardless of case" do
      expect(described_class).to be_blocked("User@Blocked.COM")
    end

    it "blocks subdomains of it" do
      expect(described_class).to be_blocked("user@mail.blocked.com")
    end

    it "does not block a domain that merely ends in the same characters" do
      expect(described_class).not_to be_blocked("user@notblocked.com")
    end

    it "does not block other domains" do
      expect(described_class).not_to be_blocked("user@example.com")
    end

    it "does not block blank values" do
      expect(described_class).not_to be_blocked(nil)
      expect(described_class).not_to be_blocked("")
    end
  end

  describe ".blocked? without configuration" do
    it "blocks nothing" do
      expect(described_class).not_to be_blocked("user@blocked.com")
    end
  end
end
