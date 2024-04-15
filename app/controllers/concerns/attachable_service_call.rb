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

module AttachableServiceCall
  ##
  # Call the presented CreateContract service
  # with the given params, merging in any attachment params
  #
  # @param service_cls the service class instance
  # @param args permitted args for the service call
  def attachable_create_call(service_cls, args:)
    service_cls
      .new(user: current_user)
      .call(args.merge(attachment_params))
  end

  ##
  # Call the presented UpdateContract service
  # with the given params, merging in any attachment params
  #
  # @param service_cls the service class instance
  # @param args permitted args for the service call
  def attachable_update_call(service_cls, model:, args:)
    service_cls
      .new(user: current_user, model:)
      .call(args.merge(attachment_params))
  end

  ##
  # Attachable parameters mapped to a format the
  # SetReplacements service concern
  def attachment_params
    attachment_params = permitted_params.attachments.to_h

    if attachment_params.any?
      { attachment_ids: attachment_params.values.map(&:values).flatten }
    else
      {}
    end
  end
end
