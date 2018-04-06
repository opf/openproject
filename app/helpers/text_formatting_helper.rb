#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module TextFormattingHelper
  extend Forwardable
  def_delegators :current_formatting_helper,
                 :text_formatting_has_preview?,
                 :text_formatting_js_includes,
                 :wikitoolbar_for,
                 :heads_for_wiki_formatter

  def preview_link(path, link_id, options = {})
    return '' unless text_formatting_has_preview?

    options = {
      accesskey: accesskey(:preview),
      id: link_id,
      'has-preview' => '',
      # NOTE:   legacy JS relies on preview class
      # FIXME:  fix preview icon naming
      class: 'button preview -with-icon icon-preview'
    }.merge(options)

    link_to path, options do
      l(:label_preview)
    end
  end

  private

  def current_formatting_helper
    helper = OpenProject::TextFormatting::Formatters.helper_for(Setting.text_formatting)
    extend helper
    self
  end
end
