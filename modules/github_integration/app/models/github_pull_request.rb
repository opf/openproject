#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class GithubPullRequest < ApplicationRecord
  STATES = %w[open closed partial].freeze
  LABEL_KEYS = %w[color name].freeze

  has_and_belongs_to_many :work_packages
  belongs_to :github_user, optional: true
  belongs_to :merged_by, optional: true, class_name: 'GithubUser'

  validates_presence_of :github_html_url,
                        :number,
                        :repository,
                        :state
  validates_presence_of :github_updated_at,
                        :title,
                        :body,
                        :comments_count,
                        :review_comments_count,
                        :additions_count,
                        :deletions_count,
                        :changed_files_count,
                        unless: :partial?
  validates :merged, inclusion: { in: [true, false] }, allow_nil: true
  validates :draft, inclusion: { in: [true, false] }, allow_nil: true
  validates :state, inclusion: { in: STATES }
  validate :validate_labels_schema

  private

  def partial?
    state == 'partial'
  end

  def validate_labels_schema
    return if labels.nil?
    return if labels.all? { |label| label.keys.sort == LABEL_KEYS }

    errors.add(:labels, 'invalid schema')
  end
end
