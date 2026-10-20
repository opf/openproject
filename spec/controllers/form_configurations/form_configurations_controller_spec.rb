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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe FormConfigurations::FormConfigurationsController do
  let(:form) { create(:type).default_variant.form_configuration }
  let(:user) { create(:admin) }

  before do
    allow(User).to receive(:current).and_return(user)
    form.update!(attribute_groups: [["People", %w[assignee]]])
  end

  describe "PATCH #reset" do
    it "puts the form back on the defaults and returns to its page" do
      patch :reset, params: { id: form.id }

      expect(response).to redirect_to(edit_form_configuration_path(form))
      expect(form.reload.form_groups.map(&:default_key)).to include("people", "details")
    end

    context "with an account that is not an administrator" do
      let(:user) { create(:user) }

      it "is refused" do
        patch :reset, params: { id: form.id }

        expect(response).to have_http_status(:forbidden)
        expect(form.reload.form_groups.map(&:label)).to eq(["People"])
      end
    end
  end
end
