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

RSpec.describe OpenProject::Common::InplaceEditFields::DisplayFields::UserSelectListComponent,
               type: :component do
  include ViewComponent::TestHelpers

  let(:user_admin) { create(:admin) }
  let(:project) { create(:project) }
  let(:custom_field) { create(:project_custom_field, :user, projects: [project]) }
  let(:attribute) { custom_field.attribute_name.to_sym }
  let(:selected_user) { create(:user) }

  before { allow(User).to receive(:current).and_return(user_admin) }

  it "renders the user avatar for a single-value user custom field" do
    create(:custom_value, :skip_validations, customized: project, custom_field:, value: selected_user.id.to_s)
    render_inline(described_class.new(model: Project.find(project.id), attribute:, writable: false, truncated: false))

    expect(rendered_content).to have_css "opce-principal"
    expect(rendered_content).to have_no_text(I18n.t("placeholders.default"))
  end

  it "renders the placeholder when no user is selected" do
    render_inline(described_class.new(model: project, attribute:, writable: false, truncated: false))

    expect(rendered_content).to have_text(I18n.t("placeholders.default"))
  end
end
