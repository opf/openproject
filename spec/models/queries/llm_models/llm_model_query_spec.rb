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

RSpec.describe Queries::LlmModels::LlmModelQuery do
  subject(:results) { described_class.new.results.pluck(:external_id) }

  let(:active_connection) { create(:llm_connection) }
  let(:inactive_connection) { create(:llm_connection, active: false) }

  before do
    create(:llm_model, llm_connection: active_connection, external_id: "qwen3.6-27b")
    create(:llm_model, llm_connection: active_connection, external_id: "bge-m3")
    create(:llm_model, llm_connection: inactive_connection, external_id: "e5-large")
  end

  it "lists the models of the active connection by identifier" do
    expect(results).to eq(["bge-m3", "qwen3.6-27b"])
  end

  it "leaves out the models of an inactive connection" do
    expect(results).not_to include("e5-large")
  end
end
