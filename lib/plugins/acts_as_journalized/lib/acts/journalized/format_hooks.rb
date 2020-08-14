#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

#-- encoding: UTF-8

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
      def register_on_journal_formatter(formatter, *field_names)
        formatter = formatter.to_sym
        journal_class = self.journal_class
        field_names.each do |field|
          JournalFormatter.register_formatted_field(journal_class.name.to_sym, field, formatter)
        end
      end

      # Shortcut to register a new proc as a named formatter. Overwrites
      # existing formatters with the same name
      def register_journal_formatter(formatter, klass = nil, &block)
        if block_given?
          klass = Class.new(JournalFormatter::Proc) do
            @proc = block
          end
        end

        raise ArgumentError 'Provide either a class or a block defining the value formatting' if klass.nil?

        JournalFormatter.register formatter.to_sym => klass
      end
    end
  end
end
