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

# Who may move a project from one variant of a type to another: whoever authors the project's own
# variants. A variant another project owns is nobody else's to use.
RSpec.describe TypeVariants::Scopes::SwitchTargets do
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:base) { type.default_variant }
  shared_let(:global) { create(:type_variant, type:, variant_name: "Mobile") }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:ours) { create(:project_owned_type_variant, type:, project:, variant_name: "Internal") }
  shared_let(:theirs) do
    create(:project_owned_type_variant, type:, project: create(:project), variant_name: "Demo only")
  end

  shared_let(:type_manager) { create(:user, member_with_permissions: { project => %i[manage_types] }) }
  shared_let(:variant_author) do
    create(:user, member_with_permissions: { project => %i[manage_project_variants] })
  end
  shared_let(:member) { create(:user, member_with_permissions: { project => %i[view_project] }) }

  def targets(user, source:)
    TypeVariant.switch_targets(user:, project:, source:)
  end

  # Selecting which types the project uses is a different job from deciding which variant of one
  # it runs on, and it does not carry it.
  describe "an administrator of the project's types" do
    it "may not switch variants" do
      expect(targets(type_manager, source: base)).to be_empty
    end
  end

  describe "an author of the project's own variants" do
    it "may switch to the variant the project owns" do
      expect(targets(variant_author, source: base)).to include(ours)
    end

    # The project's own choice among the configurations it may use, whichever of them it is on.
    it "may switch to the type's base and to a variant every project shares" do
      expect(targets(variant_author, source: ours)).to contain_exactly(base, global, ours)
    end

    it "may not switch to a variant another project owns" do
      expect(targets(variant_author, source: base)).not_to include(theirs)
    end
  end

  it "offers a plain member nothing" do
    expect(targets(member, source: base)).to be_empty
  end
end
