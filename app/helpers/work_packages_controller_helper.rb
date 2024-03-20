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

module WorkPackagesControllerHelper
  def protect_from_unauthorized_export
    if (supported_list_formats + %w[atom]).include?(params[:format]) && !user_allowed_to_export?
      deny_access
      false
    end
  end

  def user_allowed_to_export?
    User.current.allowed_in_any_work_package?(:export_work_packages, in_project: @project)
  end

  def supported_list_formats
    ::Exports::Register.list_formats(WorkPackage).map(&:to_s)
  end

  def supported_single_formats
    ::Exports::Register.single_formats(WorkPackage).map(&:to_s)
  end

  def load_and_validate_query
    @query ||= retrieve_query(@project)
    @query.name = params[:title] if params[:title].present?

    unless @query.valid?
      # Ensure outputting an html response
      request.format = 'html'
      render_400(message: @query.errors.full_messages.join(". "))
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def atom_list
    render_feed(@work_packages,
                title: "#{@project || Setting.app_title}: #{I18n.t(:label_work_package_plural)}")
  end
end
