#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/page'

module Pages
  ##
  # Use this in other Pages to fill in a bunch of fields in a form.
  # You just declare all fields to be filled in and if they are given in the fields hash.
  #
  # Example:
  #     fields = { first_name: 'Billy', last_name: 'Bland', subscribe: true }
  #     form = FormFiller.new fields
  #
  #     # declare form data
  #     form.fill_in! 'Vorname', :first_name
  #     form.fill_in! 'Nachname', :last_name
  #     form.tick! 'Newsletter', :subscribe
  #     form.select! 'Geschlecht', :gender
  #
  # The declaration section maps labels and types of input fields to field names.
  # Only the fields given to the FormFiller will actually be filled in.
  # Meaning that in this example all but the gender will be filled in.
  #
  class FormFiller < Page
    attr_reader :fields

    ##
    # Creates a new FormFiller with the given fields.
    #
    # @param fields [Hash] Arbitrary keys mapped to field values to be filled in.
    def initialize(fields)
      @fields = fields
    end

    ##
    # Fills in a text field.
    def fill!(field, key)
      fill_in field, with: fields[key] if fields.include? key
    end

    ##
    # Checks (or unchecks) a check box. 
    def set_checked!(field, key)
      if fields.include? key
        checked = fields[field]

        if checked
          check field
        else
          uncheck field
        end
      end
    end

    def select!(field, key)
      if fields.include? key
        select fields[key], from: field
      end
    end
  end
end
