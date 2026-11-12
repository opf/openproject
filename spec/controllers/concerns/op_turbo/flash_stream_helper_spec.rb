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

require "rails_helper"

RSpec.describe OpTurbo::FlashStreamHelper do
  described_module = described_class

  controller(ApplicationController) do
    include described_module

    no_authorization_required! :update

    def update
      flash_component = OpPrimer::FlashComponent
        .new(scheme: :success)
        .with_content("Saved")

      respond_with_flash(flash_component)
    end
  end

  current_user { build_stubbed(:user) }

  before do
    routes.draw { get "update" => "anonymous#update" }
  end

  it "renders an announcing flash stream" do
    get :update, as: :turbo_stream

    expect(response.body).to include '<turbo-stream action="flash"'
    expect(response.body).to include 'data-announcement="Saved"'
    expect(response.body).to include 'data-politeness="polite"'
    expect(response.body).not_to include 'action="liveRegion"'
  end
end
