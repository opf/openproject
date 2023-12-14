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

  def initialize(message: nil, full: false, spacious: false, dismissible: false, icon: nil, scheme: :default)
    super

    @message = message
    @full = full
    @spacious = spacious
    @dismissible = dismissible # TODO: not working yet -> JS dependency not provided?
    @icon = icon
    @scheme = scheme
  end

  def call
    component_wrapper do
      # even without provided message, the wrapper should be  rendered as this allows
      # for triggering a flash message via turbo stream
      if @message.present?
        flash_partial
      end
    end
  end

  private

  def flash_partial
    render(Primer::Beta::Flash.new(
             full: @full, spacious: @spacious, dismissible: @dismissible, icon: @icon, scheme: @scheme
           )) { @message }
  end
end
