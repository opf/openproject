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

RSpec.describe Projects::Settings::EditableIdentifierForm, type: :forms do
  include_context "with rendered form"

  let(:model) { build_stubbed(:project, identifier: "my-project") }

  context "when classic mode is active", with_settings: { work_packages_identifier: "classic" } do
    before do
      vc_render_form
    end

    it "renders an editable field with the legacy caption" do
      expect(page).to have_field "Identifier", with: "my-project", disabled: false
      expect(page).to have_text "Only lowercase letters (a–z), numbers, dashes or underscores."
    end
  end

  context "when semantic mode is active", with_settings: { work_packages_identifier: "semantic" } do
    before do
      vc_render_form
    end

    it "renders an editable field with the semantic caption" do
      expect(page).to have_field "Identifier", with: "my-project", disabled: false
      expect(page).to have_text "Only uppercase letters (A–Z), numbers or underscores. " \
                                "Max 10 characters. Must start with a letter."
    end
  end

end
