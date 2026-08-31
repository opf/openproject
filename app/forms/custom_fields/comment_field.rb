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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module CustomFields
  class CommentField < ApplicationForm
    form do |comment_form|
      comment_form.text_area(**attributes)
    end

    def initialize(custom_field:, object:, complete_label: false)
      super()

      @custom_field = custom_field
      @object = object
      @complete_label = complete_label
    end

    def attributes
      {
        name: @custom_field.id.to_s,
        label: @complete_label ? I18n.t(:label_custom_comment, name: @custom_field.name) : I18n.t("attributes.comment"),
        value: @object.custom_comment_for(@custom_field)&.text,
        rows: 5
      }
    end
  end
end
