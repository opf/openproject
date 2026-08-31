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

RSpec.describe "Custom logo branding", :js, with_ee: %i[define_custom_style] do
  shared_let(:admin) { create(:admin) }
  let!(:custom_style) { create(:custom_style_with_logo) }

  before do
    login_as(admin)
    visit custom_style_path(tab: "branding")
  end

  it "shows the default logo immediately after deleting the custom logo" do
    custom_logo_path = custom_style_logo_path(
      digest: custom_style.digest,
      filename: custom_style.logo_identifier
    )

    expect(desktop_logo_background).to include(custom_logo_path)

    find_test_selector("delete-custom-style-image-logo").click
    wait_for_reload

    expect(custom_style.reload.logo).not_to be_present
    expect(desktop_logo_background).not_to include(custom_logo_path)
  end

  it "shows the logo variants matching the active theme" do
    add_logo_variants
    visit custom_style_path(tab: "branding")

    apply_theme(color_mode: :light, theme: :light_high_contrast)
    expect(desktop_logo_background).to include(logo_variant_path(:logo_light_high_contrast))
    expect(mobile_logo_background).to include(logo_variant_path(:logo_mobile_light_high_contrast))

    apply_theme(color_mode: :dark, theme: :dark_high_contrast)
    expect(desktop_logo_background).to include(logo_variant_path(:logo_dark))
    expect(mobile_logo_background).to include(logo_variant_path(:logo_mobile_dark))
  end

  def desktop_logo_background
    logo_background(".op-logo--link")
  end

  def mobile_logo_background
    logo_background(".op-logo--icon")
  end

  def logo_background(selector)
    page.evaluate_script("getComputedStyle(document.querySelector('#{selector}')).backgroundImage")
  end

  def apply_theme(color_mode:, theme:)
    page.execute_script <<~JS
      document.body.setAttribute('data-color-mode', '#{color_mode}')
      document.body.removeAttribute('data-light-theme')
      document.body.removeAttribute('data-dark-theme')
      document.body.setAttribute('data-#{color_mode}-theme', '#{theme}')
    JS
  end

  def add_logo_variants
    custom_style.update!(
      logo_dark: uploaded_logo,
      logo_light_high_contrast: uploaded_logo,
      logo_mobile: uploaded_logo,
      logo_mobile_dark: uploaded_logo,
      logo_mobile_light_high_contrast: uploaded_logo
    )
  end

  def uploaded_logo
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/support/custom_styles/logos/logo_image.png")
    )
  end

  def logo_variant_path(field)
    custom_style_logo_variant_path(
      digest: custom_style.digest,
      filename: custom_style.public_send(:"#{field}_identifier"),
      variant: field
    )
  end
end
