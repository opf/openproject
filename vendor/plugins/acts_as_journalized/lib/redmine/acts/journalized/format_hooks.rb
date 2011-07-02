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

module Redmine::Acts::Journalized
  module FormatHooks
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Shortcut to register a formatter for a number of fields
      def register_on_journal_formatter(formatter, *field_names)
        formatter = formatter.to_sym
        field_names.collect(&:to_s).each do |field|
          JournalFormatter.register :class => self.journal_class.name.to_sym, field => formatter
        end
      end

      # Shortcut to register a new proc as a named formatter. Overwrites
      # existing formatters with the same name
      def register_journal_formatter(formatter)
        JournalFormatter.register formatter.to_sym => Proc.new
      end
    end
  end
end
