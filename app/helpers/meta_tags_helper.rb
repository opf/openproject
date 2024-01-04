#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module MetaTagsHelper
  ##
  # Use meta-tags to output title and site name
  def output_title_and_meta_tags
    display_meta_tags site: Setting.app_title,
                      title: html_title_parts,
                      separator: ' | ', # Update the TitleService when changing this!
                      reverse: true
  end

  def initializer_meta_tag
    tag :meta,
        name: :openproject_initializer,
        data: {
          locale: I18n.locale,
          defaultLocale: I18n.default_locale,
          instanceLocale: Setting.default_language,
          firstWeekOfYear: locale_first_week_of_year,
          firstDayOfWeek: locale_first_day_of_week,
          environment: Rails.env,
          edition: OpenProject::Configuration.edition,
          'asset-host': OpenProject::Configuration.rails_asset_host.presence
        }.compact
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
