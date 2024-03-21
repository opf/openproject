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

class WorkPackages::Exports::ScheduleService
  attr_accessor :user

  def initialize(user:)
    self.user = user
  end

  def call(query:, mime_type:, params: {})
    export_storage = WorkPackages::Export.create
    job = schedule_export(export_storage, mime_type, params, query)

    ServiceResult.success result: job.job_id
  end

  private

  def schedule_export(export_storage, mime_type, params, query)
    WorkPackages::ExportJob.perform_later(export: export_storage,
                                          user:,
                                          mime_type:,
                                          query: serialize_query(query),
                                          query_attributes: serialize_query_props(query),
                                          **params)
  end

  ##
  # Pass the query to the job if it was saved
  def serialize_query(query)
    if query.persisted?
      query
    end
  end

  def serialize_query_props(query)
    query.attributes.tap do |attributes|
      attributes['filters'] = Queries::WorkPackages::FilterSerializer.dump(query.attributes['filters'])
    end
  end
end
