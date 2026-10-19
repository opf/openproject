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

class Widget::Settings::Fieldset < Widget::Base
  dont_cache!

  def render_with_options(options, &)
    @type = options.delete(:type) || "filter"
    @id = @type.to_s
    @label = :"label_#{@type}"
    super
  end

  def render(&)
    write(
      render_view_component Primer::OpenProject::CollapsibleSection.new(id: @id, display: :block, mb: 3) do |section|
        section.with_title(tag: :h3) { I18n.t(@label) }
        section.with_collapsible_content(&)
      end
    )
  end
end
