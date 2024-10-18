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
#

module FlashMessagesHelper
  extend ActiveSupport::Concern

  included do
    include FlashMessagesOutputSafetyHelper
  end

  # Renders flash messages
  def render_flash_messages
    messages = flash
      .reject { |k, _| k.start_with? "_" }
      .reject { |k, _| k.to_s == "op_modal" }
      .map { |k, v| render_flash_content(k.to_sym, v) }

    safe_join messages, "\n"
  end

  def render_flash_content(key, content)
    case content
    when Hash
      render_flash_message(key, **content)
    else
      render_flash_message(key, message: content)
    end
  end

  def render_flash_modal
    return if (content = flash[:op_modal]).blank?

    component = content[:component]
    component = component.constantize if component.is_a?(String)

    component.new(**content.fetch(:parameters, {})).render_in(self)
  end

  def mapped_flash_type(type)
    case type
    when :error, :danger
      :danger
    when :warning
      :warning
    when :success, :notice
      :success
    else
      :default
    end
  end

  def render_flash_message(type, message:, **args)
    render(OpPrimer::FlashComponent.new(scheme: mapped_flash_type(type), **args)) do
      join_flash_messages(message)
    end
  end
end
