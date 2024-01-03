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

class Queries::WorkPackages::Filter::SearchFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  include Queries::WorkPackages::Filter::OrFilterForWpMixin

  CONTAINS_OPERATOR = '~'.freeze

  CE_FILTERS = [
    Queries::WorkPackages::Filter::FilterConfiguration.new(
      Queries::WorkPackages::Filter::SubjectFilter,
      :subject,
      CONTAINS_OPERATOR
    ),
    Queries::WorkPackages::Filter::FilterConfiguration.new(
      Queries::WorkPackages::Filter::DescriptionFilter,
      :subject,
      CONTAINS_OPERATOR
    ),
    Queries::WorkPackages::Filter::FilterConfiguration.new(
      Queries::WorkPackages::Filter::CommentFilter,
      :subject,
      CONTAINS_OPERATOR
    )
  ].freeze

  EE_TSV_FILTERS = [
    Queries::WorkPackages::Filter::FilterConfiguration.new(
      Queries::WorkPackages::Filter::AttachmentContentFilter,
      :subject,
      CONTAINS_OPERATOR
    ),
    Queries::WorkPackages::Filter::FilterConfiguration.new(
      Queries::WorkPackages::Filter::AttachmentFileNameFilter,
      :subject,
      CONTAINS_OPERATOR
    )
  ].freeze

  def type
    :search
  end

  def human_name
    I18n.t('label_search')
  end

  def custom_field_configurations
    # Does not remove custom fields that are not marked as filters
    # as the intend of this filter is to search and it is used in the
    # search context. Thus, only the searchable flag is of interest.
    custom_fields = if context&.project
                      context
                        .project
                        .all_work_package_custom_fields
                    else
                      ::WorkPackageCustomField
                    end

    custom_fields
      .where(field_format: %w(text string),
             searchable: true)
      .map do |custom_field|
      Queries::WorkPackages::Filter::FilterConfiguration.new(
        Queries::WorkPackages::Filter::CustomFieldFilter,
        custom_field.column_name,
        CONTAINS_OPERATOR
      )
    end
  end

  def filter_configurations
    list = CE_FILTERS

    list += custom_field_configurations
    list += EE_TSV_FILTERS if attachment_filters_allowed?
    list
  end

  private

  def attachment_filters_allowed?
    OpenProject::Database.allows_tsv?
  end
end
