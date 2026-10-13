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
require "spec_helper"

RSpec.describe AI::TextTransforms::EchoGateway do
  subject(:gateway) { described_class.new(delay: 0) }

  it "is always ready" do
    expect(gateway.readiness).to be_ready
  end

  it "streams the submitted content back in chunks and returns the full text" do
    deltas = []

    text = gateway.stream(system: "Fix grammar", user: "Teh quick brown fox", timeout: 10) { |delta| deltas << delta }

    expect(deltas.length).to be > 1
    expect(deltas.join).to eq(text)
    expect(text).to start_with("Teh quick brown fox")
    expect(text).to include("Fix grammar")
  end

  describe ".enabled?" do
    it "is off by default" do
      expect(described_class).not_to be_enabled
    end

    it "is on when the environment asks for it outside production" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with(described_class::ENV_KEY, false).and_return("true")

      expect(described_class).to be_enabled
    end

    it "stays off in production" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with(described_class::ENV_KEY, false).and_return("true")
      allow(Rails.env).to receive(:production?).and_return(true)

      expect(described_class).not_to be_enabled
    end
  end

  describe "AI::TextTransforms::Gateway.build" do
    it "falls back to the null gateway when no module registered one" do
      allow(AI::TextTransforms::Gateway).to receive(:factory).and_return(nil)

      expect(AI::TextTransforms::Gateway.build).to be_a(AI::TextTransforms::NullGateway)
    end

    it "hands out the echo gateway when it is enabled" do
      allow(described_class).to receive(:enabled?).and_return(true)

      expect(AI::TextTransforms::Gateway.build).to be_a(described_class)
    end
  end
end
