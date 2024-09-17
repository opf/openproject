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

  def render_primer_banner_message?
    flash[:primer_banner].present?
  end

  def render_primer_banner_message
    return unless render_primer_banner_message?

    render(BannerMessageComponent.new(**flash[:primer_banner].to_hash))
  end

  # Primer's flash message component wrapped in a component which is empty initially but can be updated via turbo stream
  def render_streameable_primer_banner_message
    render(FlashMessageComponent.new)
  end

  # Renders flash messages
  def render_flash_messages
    return if render_primer_banner_message?

    messages = flash
      .reject { |k, _| k.start_with? "_" }
      .map do |k, v|
      if k.to_sym == :modal
        component = v[:type].constantize
        component.new(**v.fetch(:parameters, {})).render_in(self)
      else
        render_flash_message(k, v)
      end
    end

    safe_join messages, "\n"
  end

  def render_flash_message(type, message, html_options = {}) # rubocop:disable Metrics/AbcSize
    if type.to_s == "notice"
      type = "success"
    end

    toast_css_classes = ["op-toast -#{type}", html_options.delete(:class)]

    # Add autohide class to notice flashes if configured
    if type.to_s == "success" && User.current.pref.auto_hide_popups?
      toast_css_classes << "autohide-toaster"
    end

    html_options = { class: toast_css_classes.join(" "), role: "alert" }.merge(html_options)
    close_button = content_tag :a, "", class: "op-toast--close icon-context icon-close",
                                       title: I18n.t("js.close_popup_title"),
                                       tabindex: "0"
    toast = content_tag(:div, join_flash_messages(message), class: "op-toast--content")
    content_tag :div, "", class: "op-toast--wrapper" do
      content_tag :div, "", class: "op-toast--casing" do
        content_tag :div, html_options do
          concat(close_button)
          concat(toast)
        end
      end
    end
  end
end
