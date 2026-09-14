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

# This file is part of the acts_as_journalized plugin for the redMine
# project management software
#
# Copyright (C) 2010  Finn GmbH, http://finn.de
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

module Acts::Journalized
  module FormatHooks
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Shortcut to register a formatter for a number of fields
      #
      # @param field_names [Array<String, Symbol, Regexp>] the fields to register the formatter for.
      # @param formatter_key [Symbol] the key of the formatter to use for these fields.
      # @param view_permission [Symbol, Proc, nil] a permission to check via
      #   User.current.allowed_in_project?, or a lambda/proc performing a custom
      #   permission check, instance_exec'd against the formatter (see
      #   JournalFormatter::Base#permission_granted?). Whether the proc receives
      #   arguments, and what they are, depends on the formatter's own
      #   permission_granted? implementation (e.g. the CustomField/CustomComment
      #   formatters instance_exec it with the CustomField being rendered).
      def register_journal_formatted_fields(*field_names, formatter_key:, view_permission: nil)
        journal_data_type = journal_class.name
        field_names.each do |field|
          JournalFormatter.register_formatted_field(journal_data_type:, field:, formatter_key:, view_permission:)
        end
      end

      def register_journal_formatter(formatter_class, formatter_key: formatter_class.name.demodulize.underscore)
        JournalFormatter.register formatter_key.to_sym => formatter_class
      end
    end
  end
end
