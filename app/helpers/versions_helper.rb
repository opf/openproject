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

module VersionsHelper
  # Returns a set of options for a select field, grouped by project.
  def version_options_for_select(versions, selected = nil)
    grouped = versions_by_project((versions + [selected]).compact)

    if grouped.size > 1
      grouped_options_for_select(grouped, selected&.id)
    else
      options_for_select((grouped.values.first || []), selected&.id)
    end
  end

  def link_to_version(version, html_options = {}, options = {})
    return '' unless version&.is_a?(Version)

    html_options = html_options.merge(id: link_to_version_id(version))

    link_name = options[:before_text].to_s.html_safe + format_version_name(version, options[:project] || @project)
    link_to_if version.visible?,
               link_name,
               { controller: '/versions', action: 'show', id: version },
               html_options
  end

  def version_dates(version)
    formatted_dates =
      %i[start_date due_date]
        .filter { |attr| version.send(attr) }
        .map { |attr| "#{Version.human_attribute_name(attr)} #{format_date(version.send(attr))}" }
    safe_join(formatted_dates, "<br>".html_safe)
  end

  def link_to_version_id(version)
    ERB::Util.url_encode("version-#{version.name}")
  end

  def format_version_name(version, project = @project)
    h(version.to_s_for_project(project))
  end

  def version_contract(version)
    if version.new_record?
      Versions::CreateContract.new(version, User.current)
    else
      Versions::UpdateContract.new(version, User.current)
    end
  end

  def format_version_sharing(sharing)
    sharing = 'none' unless Version::VERSION_SHARINGS.include?(sharing)
    t("label_version_sharing_#{sharing}")
  end

  def versions_by_project(versions)
    versions.uniq.inject(Hash.new { |h, k| h[k] = [] }) do |hash, version|
      hash[version.project.name] << [version.name, version.id]
      hash
    end
  end
end
