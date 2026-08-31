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

RSpec.describe "custom_styles/_inline_css_logo" do
  let(:custom_style) do
    logo = lambda do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec/support/custom_styles/logos/logo_image.png")
      )
    end

    create(
      :custom_style,
      logo: logo.call,
      logo_dark: logo.call,
      logo_light_high_contrast: logo.call,
      logo_mobile: logo.call,
      logo_mobile_dark: logo.call,
      logo_mobile_light_high_contrast: logo.call
    )
  end

  let(:expected_logo_paths) do
    [
      custom_style_logo_path(digest: custom_style.digest, filename: custom_style.logo_identifier),
      custom_style_logo_mobile_path(digest: custom_style.digest, filename: custom_style.logo_mobile_identifier),
      logo_variant_path(:logo_light_high_contrast),
      logo_variant_path(:logo_dark),
      logo_variant_path(:logo_mobile_light_high_contrast),
      logo_variant_path(:logo_mobile_dark)
    ]
  end

  before do
    allow(CustomStyle).to receive(:current).and_return(custom_style)
    allow(view).to receive(:apply_custom_styles?).and_return(true)

    render partial: "custom_styles/inline_css_logo"
  end

  it "renders every logo variant for its theme selectors" do
    expect(rendered).to include(*expected_logo_paths)
    expect(rendered).to include('[data-light-theme="light_high_contrast"]')
    expect(rendered).to include('[data-color-mode="dark"]')
  end

  it "reloads the page when Turbo detects changed logo CSS" do
    expect(rendered).to include('data-turbo-track="reload"')
  end

  def logo_variant_path(field)
    custom_style_logo_variant_path(
      digest: custom_style.digest,
      filename: custom_style.public_send(:"#{field}_identifier"),
      variant: field
    )
  end
end
