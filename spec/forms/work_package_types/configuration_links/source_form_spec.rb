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

RSpec.describe WorkPackageTypes::ConfigurationLinks::SourceForm do
  shared_let(:type) { create(:type, name: "Bug") }

  let(:variant) { create(:type_variant, type:, variant_name: "Configured") }

  def options_for(aspect)
    described_class.new(nil, variant:, aspect:).send(:source_options)
  end

  it "offers unrelated variants of the same type" do
    sibling = create(:type_variant, type:, variant_name: "Sibling")

    expect(options_for(TypeVariant::WORKFLOWS)).to include(type.default_variant, sibling)
  end

  it "never offers the variant being configured" do
    expect(options_for(TypeVariant::WORKFLOWS)).not_to include(variant)
  end

  it "drops a variant that inherits this aspect from the configured one" do
    dependent = create(:type_variant, type:, variant_name: "Dependent")
    dependent.link!(TypeVariant::WORKFLOWS, source: variant)

    expect(options_for(TypeVariant::WORKFLOWS)).not_to include(dependent)
  end

  it "drops a variant that inherits this aspect transitively" do
    dependent = create(:type_variant, type:, variant_name: "Dependent")
    dependent.link!(TypeVariant::WORKFLOWS, source: variant)
    grand_dependent = create(:type_variant, type:, variant_name: "Grand dependent")
    grand_dependent.link!(TypeVariant::WORKFLOWS, source: dependent)

    expect(options_for(TypeVariant::WORKFLOWS)).not_to include(grand_dependent)
  end

  it "still offers a dependent as a source for an unrelated aspect" do
    dependent = create(:type_variant, type:, variant_name: "Dependent")
    dependent.link!(TypeVariant::WORKFLOWS, source: variant)

    expect(options_for(TypeVariant::DEFAULTS)).to include(dependent)
  end
end
