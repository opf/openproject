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

RSpec.describe Webhooks::KubernetesScript, "environment variables" do
  let(:connection) { Webhooks::KubernetesConnection.create!(name: "Cluster", auth_mode: :in_cluster) }
  let(:script) do
    described_class.create!(name: "Env", kubernetes_connection: connection, image: "alpine", command: "sh",
                            body: "env", timeout_seconds: 60, environment_variables: { "API_KEY" => "secret" })
  end

  def submit(*rows)
    script.environment_variable_rows = rows.map { |name, value| { name:, value: } }
  end

  it "keeps the saved value when a row is submitted without a value" do
    submit(["API_KEY", ""], ["OTHER", "x"])

    expect(script).to be_valid
    expect(script.environment_variables).to eq("API_KEY" => "secret", "OTHER" => "x")
  end

  it "replaces a value and removes variables that are not submitted" do
    submit(["API_KEY", "new"])
    script.save!

    expect(script.reload.environment_variables).to eq("API_KEY" => "new")

    submit
    script.save!
    expect(script.reload.environment_variables).to eq({})
  end

  it "accepts the params shape of the form" do
    script.environment_variable_rows =
      ActionController::Parameters.new("0" => { name: " TOKEN ", value: "t" }, "1" => { name: "", value: "" }).permit!

    expect(script.environment_variables).to eq("TOKEN" => "t")
  end

  it "rejects invalid, reserved, duplicate and value-less names", :aggregate_failures do
    submit(["1BAD", "x"], ["OP_API_URL", "x"], ["DUP", "a"], ["DUP", "b"], ["NEW", ""])

    expect(script).not_to be_valid
    expect(script.errors.full_messages).to contain_exactly(
      "The environment variable name 1BAD is invalid. Use letters, digits and underscores, and do not start with a digit.",
      "The environment variable name OP_API_URL is reserved. Names starting with OP_ are set by OpenProject.",
      "The environment variable DUP is defined more than once.",
      "Please enter a value for the environment variable NEW."
    )
  end

  it "never returns saved values for the form" do
    submit(["API_KEY", ""], ["NEW", "typed"])

    expect(script.environment_variable_form_rows).to eq([{ name: "API_KEY", saved: true },
                                                         { name: "NEW", value: "typed", saved: false }])
  end
end
