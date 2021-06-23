#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Activities
      module ActivityPropertyFormatters
        def formatted_notes(journal)
          ::API::Decorators::Formattable.new(journal_note(journal),
                                             object: journal,
                                             plain: false)
        end

        def formatted_details(journal)
          details = render_details(journal, no_html: true)
          html_details = render_details(journal)
          formattables = details.zip(html_details)

          formattables.map { |d| { format: 'custom', raw: d[0], html: d[1] } }
        end

        private

        def render_details(journal, no_html: false)
          journal.details.map { |d| journal.render_detail(d, no_html: no_html) }
        end

        def journal_note(journal)
          if journal.noop?
            "_#{I18n.t(:'journals.changes_retracted')}_"
          else
            journal.notes
          end
        end
      end
    end
  end
end
