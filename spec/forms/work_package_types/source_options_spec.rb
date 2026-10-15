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

# The link and copy dialogs both read this list, so a leak here would expose one project's
# variant names to every other project in two places at once.
RSpec.describe WorkPackageTypes::SourceOptions do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:type) { create(:type, name: "Bug") }

  shared_let(:global) { create(:type_variant, type:, variant_name: "Global") }
  shared_let(:ours) { create(:project_owned_type_variant, type:, project:, variant_name: "Ours") }
  shared_let(:theirs) { create(:project_owned_type_variant, type:, project: other_project, variant_name: "Theirs") }

  let(:reader) do
    Class.new do
      include WorkPackageTypes::SourceOptions

      def initialize(variant)
        @variant = variant
      end

      # The module keeps these private; the spec is about what the dialogs end up offering.
      public :source_options

      private

      attr_reader :variant
    end
  end

  def options_for(variant) = reader.new(variant).source_options

  it "offers a global variant only the global sources" do
    expect(options_for(global)).to include(type.default_variant)
    expect(options_for(global)).not_to include(ours, theirs)
  end

  it "offers an owned variant the global sources" do
    expect(options_for(ours)).to include(global, type.default_variant)
  end

  # Permitted by the acceptance criteria: a sibling in the same project is a legitimate source.
  it "offers an owned variant its own project's other variants" do
    sibling = create(:project_owned_type_variant, type:, project:, variant_name: "Sibling")

    expect(options_for(ours)).to include(sibling)
  end

  it "never offers another project's variant" do
    expect(options_for(ours)).not_to include(theirs)
    expect(options_for(global)).not_to include(theirs)
  end

  it "never offers the variant being configured as its own source" do
    expect(options_for(ours)).not_to include(ours)
  end
end
