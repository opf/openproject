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

module API::V3::WorkPackages
  class ShowEndPoint < API::V3::Utilities::Endpoints::Show
    def render(request)
      timestamps = Timestamp.parse_multiple(request.params[:timestamps])
      forbidden_timestamps = timestamps - Timestamp.allowed(timestamps)

      if forbidden_timestamps.any?
        message =
          I18n.t(:"activerecord.errors.models.query.attributes.timestamps.forbidden",
                 values: forbidden_timestamps.join(", "))
        raise ::API::Errors::BadRequest.new(message)
      end

      API::V3::WorkPackages::WorkPackageRepresenter
        .create(request.instance_exec(request.params, &instance_generator),
                current_user: request.current_user,
                embed_links: true,
                timestamps:)
    end
  end
end
