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

class AvatarTextValidator < ActiveModel::EachValidator
  MAX_LENGTH = 2
  MAX_CODEPOINTS_PER_CHARACTER = 16
  MAX_MARKS_PER_CHARACTER = 4
  INVISIBLE_CODEPOINT = /[\p{Cc}\p{Cs}\p{Noncharacter_Code_Point}]|(?![\u200D\u{E0020}-\u{E007F}])\p{Cf}/
  SURROUNDING_SPACE = /\A[[:space:]\uFEFF]+|[[:space:]\uFEFF]+\z/

  def self.normalize(value)
    value.is_a?(String) ? value.gsub(SURROUNDING_SPACE, "").presence : value
  end

  def validate_each(record, attribute, value)
    characters = value.grapheme_clusters if value.is_a?(String) && value.valid_encoding?

    if characters.nil? || !characters.all? { |character| visible?(character) }
      record.errors.add(attribute, :invalid)
    elsif characters.length > MAX_LENGTH
      record.errors.add(attribute, :too_long, count: MAX_LENGTH)
    end
  end

  private

  def visible?(character)
    !character.match?(INVISIBLE_CODEPOINT) &&
      character.codepoints.length <= MAX_CODEPOINTS_PER_CHARACTER &&
      character.scan(/\p{M}/).length <= MAX_MARKS_PER_CHARACTER
  end
end
