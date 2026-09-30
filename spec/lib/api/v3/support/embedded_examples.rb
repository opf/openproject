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

RSpec.shared_examples_for "has the resource embedded" do
  let(:embedded_path) do
    super()
  rescue NoMethodError
    raise "'embedded_path' not defined in a let block"
  end
  let(:embedded_resource) do
    super()
  rescue NoMethodError
    raise "'resource' not defined in a let block. Alternatively, you can define 'resource_name' in a let block."
  end
  let(:embedded_resource_name) do
    super()
  rescue NoMethodError
    embedded_resource.name
  end
  let(:embedded_resource_type) do
    super()
  rescue NoMethodError
    embedded_resource.class.name
  end

  context "when resources are embedded" do
    let(:embed_links) { true }

    it "has the resource embedded" do
      expect(subject)
        .to be_json_eql(embedded_resource_type.to_json)
              .at_path("#{embedded_path}/_type")

      expect(subject)
        .to be_json_eql(embedded_resource.name.to_json)
              .at_path("#{embedded_path}/name")
    end
  end

  context "when resources are not embedded" do
    let(:embed_links) { false }

    it "has the resource not embedded" do
      expect(subject)
        .not_to have_json_path("#{embedded_path}/_type")
    end
  end
end

RSpec.shared_examples_for "has the resource not embedded" do
  let(:embedded_path) do
    super()
  rescue NoMethodError
    raise "'embedded_path' not defined in a let block"
  end

  it "has the resource not embedded" do
    expect(subject)
      .not_to have_json_path(embedded_path.to_s)
  end
end
