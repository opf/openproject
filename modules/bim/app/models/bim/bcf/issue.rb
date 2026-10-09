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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Bim::Bcf
  class Issue < ApplicationRecord
    self.table_name = :bcf_issues

    include InitializeWithUuid
    include VirtualAttribute

    SETTABLE_ATTRIBUTES = %i[stage labels index reference_links bim_snippet].freeze

    belongs_to :work_package
    has_one :project, through: :work_package
    has_many :viewpoints,
             -> { order(created_at: :asc) },
             foreign_key: :issue_id,
             class_name: "Bim::Bcf::Viewpoint",
             dependent: :destroy
    has_many :comments, class_name: "Bim::Bcf::Comment", dependent: :destroy

    after_update :invalidate_markup_cache

    validates :work_package, presence: true
    validates_uniqueness_of :uuid, message: :uuid_already_taken

    # The virtual attributes are defined so that an API client can attempt to set them.
    # However, currently such information is not persisted. But adding them fits better into the code
    # and might later on be replaced by an actual storing..
    virtual_attribute :reference_links do
      []
    end

    virtual_attribute :bim_snippet do
      {}
    end

    class << self
      def of_project(project)
        includes(:work_package)
          .references(:work_packages)
          .merge(WorkPackage.for_projects(project))
      end
    end

    def imported_title
      markup_doc.xpath("//Topic/Title").text
    end

    def markup_doc
      @markup_doc ||= Nokogiri::XML markup, nil, "UTF-8"
    end

    def invalidate_markup_cache
      @markup_doc = nil
    end
  end
end
