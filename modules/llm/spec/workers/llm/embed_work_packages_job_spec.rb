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

RSpec.describe Llm::EmbedWorkPackagesJob, with_flag: { semantic_search: true } do
  let(:work_package) { create(:work_package) }
  let(:semantic_index) { create(:semantic_index, state: "indexing") }

  before { allow(Llm::WorkPackages::EmbedService).to receive(:new).and_call_original }

  it "calls EmbedService with the resolved work packages" do
    service_double = instance_double(Llm::WorkPackages::EmbedService, call: nil)
    allow(Llm::WorkPackages::EmbedService).to receive(:new).and_return(service_double)

    described_class.perform_now(semantic_index.id, [work_package.id])

    expect(Llm::WorkPackages::EmbedService).to have_received(:new) do |index, wps|
      expect(index).to eq(semantic_index)
      expect(wps.map(&:id)).to contain_exactly(work_package.id)
    end
    expect(service_double).to have_received(:call)
  end

  it "does nothing once the Semantic Index is no longer indexing" do
    semantic_index.update!(state: "failed")

    described_class.perform_now(semantic_index.id, [work_package.id])

    expect(Llm::WorkPackages::EmbedService).not_to have_received(:new)
  end

  it "does nothing once the Semantic Index is gone" do
    described_class.perform_now(0, [work_package.id])

    expect(Llm::WorkPackages::EmbedService).not_to have_received(:new)
  end

  it "does nothing with the feature flag off", with_flag: { semantic_search: false } do
    described_class.perform_now(semantic_index.id, [work_package.id])

    expect(Llm::WorkPackages::EmbedService).not_to have_received(:new)
  end

  it "does nothing when pgvector is unavailable" do
    allow(OpenProject::Llm::Pgvector).to receive(:available?).and_return(false)

    described_class.perform_now(semantic_index.id, [work_package.id])

    expect(Llm::WorkPackages::EmbedService).not_to have_received(:new)
  end
end
