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

RSpec.describe WorkPackageTypes::ReloadableConfigurationFrameComponent, type: :component do
  it "wraps the content in a turbo frame reloading on the configuration-changed event" do
    render_inline(described_class.new(reload_url: "/reload/here")) { "The wrapped editor" }

    frame = page.find("turbo-frame##{described_class::FRAME_ID}")

    expect(frame.text).to include("The wrapped editor")
    expect(frame[:class]).to include("op-reloadable-configuration-frame")
    expect(frame["data-controller"]).to eq("reload-frame-on-event")
    expect(frame["data-reload-frame-on-event-event-name-value"]).to eq(described_class::RELOAD_EVENT_NAME)
    expect(frame["data-reload-frame-on-event-url-value"]).to eq("/reload/here")
  end

  it "has no src, so it is not fetched on page load" do
    render_inline(described_class.new(reload_url: "/reload/here")) { "The wrapped editor" }

    expect(page.find("turbo-frame##{described_class::FRAME_ID}")[:src]).to be_nil
  end
end
