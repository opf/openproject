# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2025 the OpenProject GmbH
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
# ++

require "rails_helper"

RSpec.describe OpStimulus::ControllerData do
  it "creates controller attribute" do
    expect(described_class.stimulus_controller_data("my--controller")).to eq("controller" => "my--controller")
  end

  it "constructs value attribute names without changing values" do
    expect(
      described_class.stimulus_controller_data(
        "my--namespaced--controller",
        a_string: "foo_bar",
        an_integer: 1,
        a_boolean: false,
        an_absent_value: nil
      )
    ).to eq(
      "controller" => "my--namespaced--controller",
      "my--namespaced--controller-a-string-value" => "foo_bar",
      "my--namespaced--controller-an-integer-value" => 1,
      "my--namespaced--controller-a-boolean-value" => false,
      "my--namespaced--controller-an-absent-value-value" => nil
    )
  end
end
