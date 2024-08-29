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
  class Comment < ApplicationRecord
    self.table_name = :bcf_comments

    include InitializeWithUuid

    CREATE_ATTRIBUTES = %i[journal issue viewpoint reply_to].freeze
    UPDATE_ATTRIBUTES = %i[viewpoint reply_to].freeze

    belongs_to :journal
    belongs_to :issue, class_name: "Bim::Bcf::Issue"
    belongs_to :viewpoint, class_name: "Bim::Bcf::Viewpoint", optional: true
    belongs_to :reply_to, foreign_key: :reply_to, class_name: "Bim::Bcf::Comment", optional: true

    validates_presence_of :uuid
    validates_uniqueness_of :uuid, scope: [:issue_id]

    def self.has_uuid?(uuid, issue_id)
      exists?(uuid:, issue_id:)
    end
  end
end
