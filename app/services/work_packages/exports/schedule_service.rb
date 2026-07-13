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

class WorkPackages::Exports::ScheduleService
  attr_accessor :user

  # Allowed option keys for the export pipeline from user input
  PERMITTED_EXPORT_OPTIONS = %i[
    filter_empty
    footer_text
    footer_text_center
    format
    gantt_mode
    gantt_width
    header_text_right
    hyphenation
    hyphenation_language
    language
    long_text_fields
    no_columns
    page
    page_orientation
    paper_size
    pdf_export_type
    save_export_settings
    show_descriptions
    show_images
    show_relations
  ].freeze

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
                                          options: export_options(params))
  end

  def export_options(params)
    params.permit(*PERMITTED_EXPORT_OPTIONS, columns: []).to_h
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
      attributes["filters"] = Queries::WorkPackages::FilterSerializer.dump(query.attributes["filters"])
    end
  end
end
