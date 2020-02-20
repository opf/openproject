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

module WarningBarHelper
  def render_pending_migrations_warning?
    current_user.admin? &&
      OpenProject::Configuration.show_pending_migrations_warning? &&
      OpenProject::Database.migrations_pending?
  end

  def render_host_and_protocol_mismatch?
    current_user.admin? &&
      OpenProject::Configuration.show_setting_mismatch_warning? &&
      (setting_protocol_mismatched? || setting_hostname_mismatched?)
  end

  def setting_protocol_mismatched?
    (request.ssl? && Setting.protocol == 'http') || (!request.ssl? && Setting.protocol == 'https')
  end

  def setting_hostname_mismatched?
    Setting.host_name.gsub(/:\d+$/, '') != request.host
  end

  ##
  # By default, never show a warning bar in the
  # test mode due to overshadowing other elements.
  def show_warning_bar?
    OpenProject::Configuration.show_warning_bars?
  end
end
