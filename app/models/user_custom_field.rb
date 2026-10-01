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

class UserCustomField < CustomField
  include CustomField::Sectionable

  belongs_to :user_custom_field_section, class_name: "UserCustomFieldSection", foreign_key: :custom_field_section_id,
                                         inverse_of: :custom_fields

  enum :semantic_key, { job_title: "job_title" }, prefix: true

  validates :semantic_key, uniqueness: { scope: :type }, allow_nil: true

  scopes :visible

  scope :with_semantic_key, ->(semantic_key) { where(semantic_key:) }

  def self.for_semantic_key(semantic_key)
    with_semantic_key(semantic_key).first
  end

  def type_name
    :label_user_plural
  end
end
