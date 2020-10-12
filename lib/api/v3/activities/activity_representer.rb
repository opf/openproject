#-- encoding: UTF-8
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

API::V3::Utilities::DateTimeFormatter

module API
  module V3
    module Activities
      class ActivityRepresenter < ::API::Decorators::Single
        include API::V3::Utilities
        include API::Decorators::DateProperty
        include API::Decorators::FormattableProperty

        self_link path: :activity,
                  id_attribute: :notes_id,
                  title_getter: ->(*) { nil }

        link :workPackage do
          {
            href: api_v3_paths.work_package(represented.journable.id),
            title: "#{represented.journable.subject}"
          }
        end

        link :user do
          {
            href: api_v3_paths.user(represented.user_id)
          }
        end

        link :update do
          next unless current_user_allowed_to_edit?

          {
            href: api_v3_paths.activity(represented.notes_id),
            method: :patch
          }
        end

        property :id,
                 getter: ->(*) { notes_id },
                 render_nil: true

        formattable_property :notes,
                             as: :comment,
                             getter: ->(*) {
                               text = if represented.noop?
                                        "_#{I18n.t(:'journals.changes_retracted')}_"
                                      else
                                        represented.notes
                                      end

                               ::API::Decorators::Formattable.new(text,
                                                                  object: represented,
                                                                  plain: false)
                             }

        property :details,
                 exec_context: :decorator,
                 getter: ->(*) {
                   details = render_details(represented, no_html: true)
                   html_details = render_details(represented)
                   formattables = details.zip(html_details)

                   formattables.map { |d| { format: 'custom', raw: d[0], html: d[1] } }
                 },
                 render_nil: true

        property :version, render_nil: true

        date_time_property :created_at

        def _type
          if represented.noop? || represented.notes.present?
            'Activity::Comment'
          else
            'Activity'
          end
        end

        private

        def current_user_allowed_to_edit?
          represented.editable_by?(current_user)
        end

        def render_details(journal, no_html: false)
          journal.details.map { |d| journal.render_detail(d, no_html: no_html) }
        end
      end
    end
  end
end
