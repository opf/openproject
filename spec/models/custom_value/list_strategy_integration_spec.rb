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

RSpec.describe CustomValue::ListStrategy, "integration tests" do
  let(:type) { create(:type) }
  let(:project) { create(:project, types: [type]) }
  let!(:custom_field) do
    create(
      :list_wp_custom_field,
      name: "Invalid List CF",
      multi_value: true,
      types: [type],
      projects: [project],
      possible_values: ["A", "B"]
    )
  end

  let!(:work_package) do
    create(:work_package,
           project:,
           type:,
           custom_values: { custom_field.id => custom_field.custom_options.find_by(value: "A") })
  end

  it "can handle invalid CustomOptions (Regression test)" do
    expect(work_package.public_send(custom_field.attribute_getter)).to eq(%w(A))

    # Remove the custom value without replacement
    CustomValue.find_by(customized_id: work_package.id).update_columns(value: "invalid")
    work_package.reload
    work_package.reset_custom_values!

    expect(work_package.public_send(custom_field.attribute_getter)).to eq(["invalid not found"])
  end
end
