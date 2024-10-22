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

xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  first_item = @items.first
  first_item_event = !first_item.nil? && first_item.respond_to?(:data) ? first_item.data : first_item
  updated_time = first_item_event.nil? ? Time.now : first_item_event.event_datetime

  xml.title truncate_single_line(@title, length: 100)
  xml.link "rel" => "self", "href" => url_for(only_path: false)
  xml.link "rel" => "alternate", "href" => url_for(only_path: false, format: nil, key: nil)
  xml.id url_for(controller: "/homescreen", action: :index, only_path: false)
  xml.updated(updated_time.xmlschema)
  xml.author { xml.name Setting.app_title }
  xml.generator(uri: OpenProject::Info.url) { xml.text! OpenProject::Info.app_name }
  @items.each do |item|
    item_event = item.try(:data) || item

    xml.entry do
      url =
        if item_event.is_a? Activities::Event
          item_event.event_url
        else
          url_for(item_event.event_url(only_path: false))
        end
      if @project
        xml.title truncate_single_line(item_event.event_title, length: 100)
      else
        xml.title truncate_single_line("#{item.project} - #{item_event.event_title}", length: 100)
      end
      xml.link "rel" => "alternate", "href" => url
      xml.id url
      xml.updated item_event.event_datetime.xmlschema
      author = item_event.event_author if item_event.respond_to?(:event_author)
      if author
        xml.author do
          xml.name(author)
          if author.is_a?(User) && author.mail.present? && User.current.allowed_globally?(:view_user_email)
            xml.email(author.mail)
          end
        end
      end
      xml.content "type" => "html" do
        xml.text! format_text(item_event, :event_description, only_path: false)
      end
    end
  end
end
