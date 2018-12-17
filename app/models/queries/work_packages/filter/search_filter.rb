#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Queries::WorkPackages::Filter::SearchFilter < Queries::WorkPackages::Filter::OrBaseFilter
  include Queries::WorkPackages::Filter::FilterOnTsvMixin
  CONTAINS_OPERATOR = '~'.freeze

  CE_FILTERS = [
    [Queries::WorkPackages::Filter::SubjectFilter, :subject, CONTAINS_OPERATOR],
    [Queries::WorkPackages::Filter::DescriptionFilter, :description, CONTAINS_OPERATOR],
    [Queries::WorkPackages::Filter::CommentFilter, :description, CONTAINS_OPERATOR]
  ].freeze

  EE_TSV_FILTERS = [
    [Queries::WorkPackages::Filter::AttachmentContentFilter, :attachment_content, CONTAINS_OPERATOR],
    [Queries::WorkPackages::Filter::AttachmentFileNameFilter, :attachment_file_name, CONTAINS_OPERATOR]
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

  def filter_configurations
    list = CE_FILTERS
    list + EE_TSV_FILTERS if EnterpriseToken.allows_to?(:attachment_filters) && OpenProject::Database.allows_tsv?
  end
end
