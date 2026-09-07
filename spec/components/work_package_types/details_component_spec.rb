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

require "rails_helper"

RSpec.describe WorkPackageTypes::DetailsComponent, type: :component do
  shared_let(:bug) { create(:type, name: "Bug") }

  current_user { create(:admin) }

  let(:checkbox_label) { "Allow project-specific variants" }

  context "with the variants feature enabled", with_flag: { type_variants: true } do
    it "offers the setting on the type" do
      render_inline(described_class.new(bug))

      expect(page).to have_field(checkbox_label)
      expect(page).to have_text("this type can be extended or modified within a project")
    end

    it "leaves it out on a variant, which the type decides it for" do
      render_inline(described_class.new(create(:type_variant, type: bug, variant_name: "Hardware")))

      expect(page).to have_no_field(checkbox_label)
    end
  end

  context "with the variants feature disabled" do
    it "leaves it out" do
      render_inline(described_class.new(bug))

      expect(page).to have_no_field(checkbox_label)
    end
  end
end
