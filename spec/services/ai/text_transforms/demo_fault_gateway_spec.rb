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

RSpec.describe AI::TextTransforms::DemoFaultGateway do
  let(:inner) { AI::TextTransforms::FakeGateway.new(deltas: %w[a b]) }
  let(:gateway) { described_class.new(inner) }

  def stream(system)
    deltas = []
    gateway.stream(system:, user: "input", timeout: 5) { |delta| deltas << delta }
    deltas
  end

  it "passes an unmarked prompt through untouched" do
    expect(stream("prompt")).to eq(%w[a b])
    expect(inner.calls.first[:system]).to eq("prompt")
  end

  it "fails before streaming and strips the marker for a failed fault" do
    expect { stream(described_class.mark("prompt", "failed")) }
      .to raise_error(AI::TextTransforms::Errors::ConnectionFailed)
    expect(inner.calls).to be_empty
  end

  it "streams the deltas and then reports the stream as blocked" do
    deltas = []

    expect { gateway.stream(system: described_class.mark("prompt", "blocked"), user: "input", timeout: 5) { |d| deltas << d } }
      .to raise_error(AI::TextTransforms::Errors::Blocked)
    expect(deltas).to eq(%w[a b])
    expect(inner.calls.first[:system]).to eq("prompt")
  end

  it "ignores unknown faults when marking" do
    expect(described_class.mark("prompt", "whatever")).to eq("prompt")
  end

  it "delegates readiness" do
    expect(gateway.readiness).to be_ready
  end
end
