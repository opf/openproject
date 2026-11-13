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

RSpec.describe "Fixed theme first paint", type: :rails_request do
  def sign_in_with_theme(theme, increase_theme_contrast:)
    login_as create(:user, preferences: { theme:, increase_theme_contrast: })
    get "/my/page"

    expect(response).to have_http_status(:ok)
  end

  {
    ["light", false] => "body[data-color-mode='light'][data-light-theme='light']",
    ["light", true] => "body[data-color-mode='light'][data-light-theme='light_high_contrast']",
    ["dark", false] => "body[data-color-mode='dark'][data-dark-theme='dark']",
    ["dark", true] => "body[data-color-mode='dark'][data-dark-theme='dark_high_contrast']"
  }.each do |(theme, increase_theme_contrast), selector|
    it "serves the #{theme} theme#{' with high contrast' if increase_theme_contrast} on the body without JavaScript" do
      sign_in_with_theme(theme, increase_theme_contrast:)

      expect(page).to have_css(selector)
    end
  end
end
