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

# Which configurations a variant may borrow from. Enforced on the record rather than only where
# the source is picked, because the pickers are a courtesy and the write endpoints take an id.
RSpec.describe TypeVariant, "the sources a variant may borrow from" do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:type) { create(:type, name: "Bug") }

  shared_let(:global) { create(:type_variant, type:, variant_name: "Global") }
  shared_let(:ours) { create(:project_owned_type_variant, type:, project:, variant_name: "Ours") }
  shared_let(:sibling) { create(:project_owned_type_variant, type:, project:, variant_name: "Sibling") }
  shared_let(:theirs) { create(:project_owned_type_variant, type:, project: other_project, variant_name: "Theirs") }

  def link(variant, source)
    variant.defaults_source = source
    variant
  end

  describe "a variant a project owns" do
    it "may borrow from a global variant" do
      expect(link(ours, global)).to be_valid
    end

    it "may borrow from the type's own configuration" do
      expect(link(ours, type.default_variant)).to be_valid
    end

    it "may borrow from a sibling its own project owns" do
      expect(link(ours, sibling)).to be_valid
    end

    it "may not borrow from another project's variant" do
      subject = link(ours, theirs)

      expect(subject).not_to be_valid
      expect(subject.errors[:defaults_source_id])
        .to include("must be a configuration this project can use.")
    end
  end

  describe "a global variant" do
    it "may borrow from another global variant" do
      expect(link(global, type.default_variant)).to be_valid
    end

    # The rule is about the variant, not about who is editing it. An administrator sees every
    # project's variants, and linking one project's configuration into a global one would hand
    # that project's settings to every project at once.
    it "may not borrow from a variant a project owns" do
      subject = link(global, ours)

      expect(subject).not_to be_valid
    end
  end

  # No mount, controller or console call can route around it.
  it "refuses to save a cross-project link at all" do
    expect { link(ours, theirs).save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "leaves the existing cycle rule intact" do
    subject = link(ours, ours)

    expect(subject).not_to be_valid
    expect(subject.errors[:defaults_source_id]).to include("would link these configurations in a loop.")
  end
end
