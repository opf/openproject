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

module BreadcrumbHelper
  def full_breadcrumbs
    render(Primer::Beta::Breadcrumbs.new(test_selector: "op-breadcrumb")) do |breadcrumbs|
      breadcrumb_paths.each_with_index do |item, index|
        item = anchor_string_to_object(item) if item.is_a?(String) && item.start_with?("\u003c")

        if item.is_a?(Hash)
          breadcrumbs.with_item(href: item[:href], classes: index == 0 ? "first-breadcrumb-element" : nil) { item[:text] }
        else
          breadcrumbs.with_item(href: "#", classes: index == 0 ? "first-breadcrumb-element" : nil) { item }
        end
      end
    end
  end

  def breadcrumb_paths(*args)
    if args.empty?
      @breadcrumb_paths ||= [default_breadcrumb]
    else
      @breadcrumb_paths ||= []
      @breadcrumb_paths += args.flatten.compact
    end
  end

  def show_breadcrumb
    if !!(defined? show_local_breadcrumb)
      show_local_breadcrumb
    else
      false
    end
  end

  private

  # transform anchor tag strings to {href, text} objects
  # e.g "\u003ca href=\"/admin\"\u003eAdministration\u003c/a\u003e"
  def anchor_string_to_object(html_string)
    # Parse the HTML
    doc = Nokogiri::HTML.fragment(html_string)
    # Extract href and text
    anchor = doc.at("a")
    { href: anchor["href"], text: anchor.text }
  end
end
