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

RSpec.describe OpenProject::Common::InplaceEditFields::DisplayFields::LinkInputComponent,
               type: :component do
  include ViewComponent::TestHelpers

  let(:project) { build_stubbed(:project) }

  it "renders a link for a URL value" do
    without_partial_double_verification do
      allow(project).to receive(:homepage).and_return("https://example.com")
      render_inline(described_class.new(model: project, attribute: :homepage, writable: false, truncated: false))

      expect(rendered_content).to have_link("https://example.com", href: "https://example.com")
    end
  end

  it "renders a placeholder when the value is blank" do
    without_partial_double_verification do
      allow(project).to receive(:homepage).and_return(nil)
      render_inline(described_class.new(model: project, attribute: :homepage, writable: false, truncated: false))

      expect(rendered_content).to have_text(I18n.t("placeholders.default"))
    end
  end
end
