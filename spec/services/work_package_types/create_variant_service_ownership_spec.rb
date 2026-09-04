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

RSpec.describe WorkPackageTypes::CreateVariantService, "owning project" do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:admin) { create(:admin) }
  shared_let(:project_admin) do
    create(:user, member_with_permissions: { project => %i[manage_project_variants] })
  end

  def call(user:, project: nil)
    described_class.new(user:, type:).call(variant_name: "Internal", project:)
  end

  describe "a project administrator" do
    it "creates a variant their project owns" do
      result = call(user: project_admin, project:)

      expect(result).to be_success, -> { result.errors.full_messages.to_sentence }
      expect(result.result.project).to eq(project)
    end

    it "cannot create one owned by another project" do
      expect(call(user: project_admin, project: other_project)).to be_failure
    end

    # A global variant is instance configuration, so it stays with the administrators.
    it "cannot create a global one" do
      expect(call(user: project_admin, project: nil)).to be_failure
    end
  end

  describe "an instance administrator" do
    it "creates a global variant" do
      expect(call(user: admin, project: nil)).to be_success
    end

    it "creates one owned by any project" do
      result = call(user: admin, project:)

      expect(result).to be_success
      expect(result.result.project).to eq(project)
    end
  end

  it "links every aspect to the type's base configuration, as for a global variant" do
    variant = call(user: project_admin, project:).result

    TypeVariant::ASPECTS.each do |aspect|
      expect(variant.public_send(:"#{aspect}_source")).to eq(type.default_variant)
    end
  end
end
