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

module HomescreenHelper
  ##
  # Homescreen name
  def organization_name
    Setting.app_title || Setting.software_name
  end

  ##
  # Homescreen organization icon
  def organization_icon
    op_icon('icon-context icon-enterprise')
  end

  ##
  # Render a static link defined in OpenProject::Static::Links
  def static_link_to(key)
    link = OpenProject::Static::Links.links[key]
    label = I18n.t(link[:label])

    link_to label,
            link[:href],
            title: label,
            target: '_blank', rel: 'noopener'
  end

  ##
  # Determine whether we should render the links on homescreen?
  def show_homescreen_links?
    EnterpriseToken.show_banners? || OpenProject::Configuration.show_community_links?
  end

  ##
  # Determine whether we should render the onboarding modal
  def show_onboarding_modal?
    OpenProject::Configuration.onboarding_enabled? && params[:first_time_user]
  end
end
