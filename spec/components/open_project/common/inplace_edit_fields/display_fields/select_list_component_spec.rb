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

RSpec.describe OpenProject::Common::InplaceEditFields::DisplayFields::SelectListComponent,
               type: :component do
  include ViewComponent::TestHelpers

  let(:project) { build_stubbed(:project) }

  it "renders a single string value" do
    without_partial_double_verification do
      allow(project).to receive(:status_label).and_return("Active")
      render_inline(described_class.new(model: project, attribute: :status_label, writable: false, truncated: false))

      expect(rendered_content).to have_text("Active")
    end
  end

  it "renders multiple values joined by comma" do
    without_partial_double_verification do
      allow(project).to receive(:tag_list).and_return(%w[Alpha Beta])
      render_inline(described_class.new(model: project, attribute: :tag_list, writable: false, truncated: false))

      expect(rendered_content).to have_text("Alpha, Beta")
    end
  end

  it "renders a placeholder when the value is blank" do
    without_partial_double_verification do
      allow(project).to receive(:status_label).and_return(nil)
      render_inline(described_class.new(model: project, attribute: :status_label, writable: false, truncated: false))

      expect(rendered_content).to have_text(I18n.t("placeholders.default"))
    end
  end
end
