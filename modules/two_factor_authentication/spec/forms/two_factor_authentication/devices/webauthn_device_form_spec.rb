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

RSpec.describe TwoFactorAuthentication::Devices::WebauthnDeviceForm, type: :forms do
  include_context "with rendered form"

  let(:model) { TwoFactorAuthentication::Device::Webauthn.new }
  let(:params) { { index_path: "/my/two_factor_devices" } }

  it "renders the fields the Stimulus controller operates on" do
    expect(page).to have_field("Identifier", required: true)
    expect(page).to have_field("device[webauthn_credential]",
                               type: :hidden,
                               with: "")
  end

  # Regression #OP-19758: a control named after an HTMLFormElement method shadows it, so the
  # Stimulus controller could no longer submit the form after creating the credential.
  it "does not name any control after a form method the Stimulus controller calls" do
    expect(page).to have_no_css("[name=submit], [name=requestSubmit]", visible: :all)
  end
end
