#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

module MetaTagsHelper
  ##
  # Use meta-tags to output title and site name
  def output_title_and_meta_tags
    display_meta_tags site: Setting.app_title,
                      title: html_title_parts,
                      separator: ' | ', # Update the TitleService when changing this!
                      reverse: true
  end

  ##
  # Writer of html_title as string
  def html_title(*args)
    raise "Don't use html_title getter" if args.empty?

    @html_title ||= []
    @html_title += args
  end

  ##
  # The html title parts currently defined
  def html_title_parts
    [].tap do |parts|
      parts << h(@project.name) if @project
      parts.concat @html_title.map(&:to_s) if @html_title
    end
  end
end
