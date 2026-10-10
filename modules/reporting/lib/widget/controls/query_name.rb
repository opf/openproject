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

class Widget::Controls::QueryName < Widget::Controls
  def initialize(...)
    super

    @system_arguments = { id: "query_saved_name", data: { translations: } }
    @name = if @subject.new_record?
              I18n.t(:label_new_report)
            else
              @subject.name
            end
    @system_arguments[:"data-is_new"] = false unless @subject.new_record?
  end

  def call
    render Primer::Beta::Text.new(**@system_arguments).with_content(@name)
  end

  def translations
    { isPublic: I18n.t(:public, scope: "attributes") }.to_json
  end
end
