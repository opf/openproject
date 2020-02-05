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

class Queries::WorkPackages::Filter::SearchFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  include Queries::WorkPackages::Filter::OrFilterForWpMixin
  include Queries::WorkPackages::Filter::FilterOnTsvMixin

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

  def self.key
    :search
  end

  def name
    :search
  end

  def type
    :search
  end

  def human_name
    I18n.t('label_search')
  end

  def custom_field_configurations
    custom_fields =
      if context&.project
        context.project.all_work_package_custom_fields.select do |custom_field|
          %w(text string).include?(custom_field.field_format) &&
            custom_field.is_filter == true &&
            custom_field.searchable == true
        end
      else
        ::WorkPackageCustomField
          .filter
          .for_all
          .where(field_format: %w(text string),
                 is_filter: true,
                 searchable: true)
      end

    custom_fields.map do |custom_field|
      Queries::WorkPackages::Filter::FilterConfiguration.new(
        Queries::WorkPackages::Filter::CustomFieldFilter,
        "cf_#{custom_field.id}",
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
    EnterpriseToken.allows_to?(:attachment_filters) && OpenProject::Database.allows_tsv?
  end
end
