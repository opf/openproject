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

module Bim::Bcf
  class Viewpoint < ApplicationRecord
    self.table_name = :bcf_viewpoints

    include InitializeWithUuid

    acts_as_attachable view_permission: :view_linked_issues,
                       delete_permission: :manage_bcf,
                       add_on_new_permission: :manage_bcf,
                       add_on_persisted_permission: :manage_bcf

    def self.has_uuid?(uuid)
      where(uuid:).exists?
    end

    belongs_to :issue,
               class_name: "Bim::Bcf::Issue",
               touch: true

    has_many :comments, class_name: "Bim::Bcf::Comment"
    delegate :project, :project_id, to: :issue, allow_nil: true

    validates :issue, presence: true

    def raw_json_viewpoint
      attributes_before_type_cast["json_viewpoint"]
    end

    def snapshot
      if attachments.loaded?
        attachments.detect { |a| a.description == "snapshot" }
      else
        attachments.find_by_description("snapshot")
      end
    end

    def clipping_planes?
      json_viewpoint && json_viewpoint["clipping_planes"]
    end

    def snapshot=(file)
      snapshot&.destroy
      build_snapshot file
    end

    def build_snapshot(file, user: User.current)
      ::Attachments::BuildService
        .bypass_whitelist(user:)
        .call(file:, container: self, filename: file.original_filename, description: "snapshot")
        .result
    end
  end
end
