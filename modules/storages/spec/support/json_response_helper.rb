# frozen_string_literal: true

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

module JsonResponseHelper
  def read_json(name)
    File.readlines(payload_path.join("#{name}.json")).join
  end

  private

  def payload_path
    Pathname.new(Rails.root).join("modules/storages/spec/support/payloads/")
  end

  def not_found_response
    {
      error: {
        code: "itemNotFound",
        message: "The resource could not be found.",
        innerError: {
          date: "2023-09-08T08:20:55",
          "request-id": "286b0215-7f33-46dc-b1fe-67720fe1616a",
          "client-request-id": "286b0215-7f33-46dc-b1fe-67720fe1616a"
        }
      }
    }.to_json
  end

  def forbidden_response
    {
      error: {
        code: "accessDenied",
        message: "Access denied",
        innerError: {
          date: "2023-09-08T08:20:55",
          "request-id": "286b0215-7f33-46dc-b1fe-67720fe1616f",
          "client-request-id": "286b0215-7f33-46dc-b1fe-67720fe1616b"
        }
      }
    }.to_json
  end
end
