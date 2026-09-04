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

module WorkPackageTypes
  class PatternResolver
    ATTRIBUTE_PLACEHOLDER = "N/A"

    def initialize(pattern)
      @mapper = Patterns::TokenPropertyMapper.new
      @pattern = pattern
      @pattern_tokens = Patterns::PatternToken.scan_tokens(pattern)
    end

    def resolve(work_package)
      @tokens, = @mapper.partitioned_tokens_for_type(work_package.type_variant)

      @pattern_tokens.inject(@pattern) do |pattern, token|
        pattern.gsub(token.pattern, get_value(work_package, token))
      end
    end

    private

    def get_value(work_package, pattern_token)
      attribute_token = @tokens.detect { |t| t.key == pattern_token.key }
      return ATTRIBUTE_PLACEHOLDER if attribute_token.nil?

      context = attribute_token.context == :work_package ? work_package : work_package.public_send(attribute_token.context)
      return ATTRIBUTE_PLACEHOLDER if context.nil?

      I18n.with_locale(Setting.default_language) do
        stringify(attribute_token.call(context, pattern_token.format), nil_replacement(attribute_token))
      end
    end

    def nil_replacement(attribute_token)
      if attribute_token.context == :work_package
        "[#{attribute_token.label}]"
      else
        "[#{attribute_token.label_with_context}]"
      end
    end

    def stringify(value, nil_fallback)
      case value
      when NilClass
        nil_fallback
      when :attribute_not_available
        ATTRIBUTE_PLACEHOLDER
      else
        value
      end
    end
  end
end
