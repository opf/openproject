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
require_module_spec_helper

RSpec.describe Storages::Storage do
  describe "#health_notifications_should_be_sent?" do
    let(:storage) { build(:storage, provider_fields: {}) }

    context "when health_notifications_enabled is nil" do
      it "relies on automatic_management_enabled" do
        storage.automatic_management_enabled = false
        expect(storage.health_notifications_should_be_sent?).to be(false)

        storage.automatic_management_enabled = true
        expect(storage.health_notifications_should_be_sent?).to be(true)
      end
    end

    context "when health_notifications_enabled is not nil" do
      it "relies on health_notifications_enabled" do
        storage.automatic_management_enabled = false
        storage.health_notifications_enabled = false
        expect(storage.health_notifications_should_be_sent?).to be(false)

        storage.automatic_management_enabled = true
        storage.health_notifications_enabled = false
        expect(storage.health_notifications_should_be_sent?).to be(false)

        storage.automatic_management_enabled = false
        storage.health_notifications_enabled = true
        expect(storage.health_notifications_should_be_sent?).to be(true)

        storage.automatic_management_enabled = false
        storage.health_notifications_enabled = true
        expect(storage.health_notifications_should_be_sent?).to be(true)
      end
    end
  end

  describe "provider_fields" do
    let(:storage) { build(:storage, provider_fields: {}) }

    shared_examples "a stored boolean attribute" do |attribute|
      it "#{attribute} has a default value of false" do
        expect(storage.public_send(:"#{attribute}?")).to be(false)
      end

      ["1", "true", true].each do |boolean_like|
        context "with truthy value #{boolean_like}" do
          it "sets #{attribute} to true" do
            storage.public_send(:"#{attribute}=", boolean_like)
            expect(storage.public_send(attribute)).to be(true)
          end
        end
      end

      it "#{attribute} can be set to true" do
        storage.public_send(:"#{attribute}=", true)

        expect(storage.public_send(attribute)).to be(true)
        expect(storage.public_send(:"#{attribute}?")).to be(true)
      end
    end

    describe "#automatically_managed" do
      it_behaves_like "a stored boolean attribute", :automatically_managed
    end

    describe "#automatic_management_enabled?" do
      context "when automatic management enabled is true" do
        let(:storage) { build(:storage, automatic_management_enabled: true) }

        it { expect(storage).to be_automatic_management_enabled }
      end

      context "when automatic management enabled is false" do
        let(:storage) { build(:storage, automatic_management_enabled: false) }

        it { expect(storage).not_to be_automatic_management_enabled }
      end

      context "when automatic management enabled is nil" do
        let(:storage) { build(:storage, automatic_management_enabled: nil) }

        it { expect(storage.automatic_management_enabled?).to be(false) }
      end
    end
  end

  describe "uri" do
    it "returns nil if host is nil" do
      storage = build(:storage, host: nil)
      expect(storage.uri).to be_nil
    end

    it "returns host with trailing slash" do
      storage = build(:storage, host: "https://example.com")
      expect(storage.uri.to_s).to eq("https://example.com/")
      storage = build(:storage, host: "https://endor")
      expect(storage.uri.to_s).to eq("https://endor/")
      storage = build(:storage, host: "https://deathstar.org/html")
      expect(storage.uri.to_s).to eq("https://deathstar.org/html/")

      storage = build(:storage, host: "https://example.com/")
      expect(storage.uri.to_s).to eq("https://example.com/")
      storage = build(:storage, host: "https://endor/")
      expect(storage.uri.to_s).to eq("https://endor/")
      storage = build(:storage, host: "https://deathstar.org/html/")
      expect(storage.uri.to_s).to eq("https://deathstar.org/html/")
    end
  end
end
