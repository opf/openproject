#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class FlashMessageComponent < ApplicationComponent
  include ApplicationHelper
  include OpTurbo::Streamable
  include OpPrimer::ComponentHelpers

  def initialize(message: nil, full: false, full_when_narrow: false, dismissible: false, icon: false, scheme: :default,
                 test_selector: "primer-flash-message-component")
    super

    @message = message
    @full = full
    @full_when_narrow = full_when_narrow
    @dismissible = dismissible
    @icon = icon
    @scheme = scheme
    @test_selector = test_selector
  end

  def call
    component_wrapper do
      # even without provided message, the wrapper should be  rendered as this allows
      # for triggering a flash message via turbo stream
      if message.present?
        flash_partial
      end
    end
  end

  private

  attr_reader :message, :full, :full_when_narrow, :dismissible, :icon, :scheme, :test_selector

  def flash_partial
    # The banner component is similar to the flash message component, but is more feature rich.
    #  - It ALWAYS renders with an icon
    #  - It can be dismissed
    #  - It allows for custom actions while flash messages only allow for a dismiss action (which doesn't work yet :/)
    # See https://primer.style/components/banner/rails/alpha
    render(
      Primer::Alpha::Banner.new(
        full:, full_when_narrow:,
        dismiss_scheme:, icon:, scheme:,
        test_selector:
      )
    ) { message }
  end

  def dismiss_scheme
    dismissible ? :remove : :none
  end
end
