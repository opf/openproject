#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/representer/json/hal'

module API
  module V3
    module Activities
      class ActivityRepresenter < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::Feature::Hypermedia
        include OpenProject::StaticRouting::UrlHelpers

        self.as_strategy = API::Utilities::CamelCasingStrategy.new

        property :_type, exec_context: :decorator

        link :self do
          { href: "#{root_url}api/v3/activities/#{represented.journal.id}", title: "#{represented.journal.id}" }
        end

        link :work_package do
          { href: "#{root_url}api/v3/work_packages/#{represented.journal.journable.id}", title: "#{represented.journal.journable.subject}" }
        end

        link :user do
          { href: "#{root_url}api/v3/users/#{represented.journal.user.id}", title: "#{represented.journal.user.name} - #{represented.journal.user.login}" }
        end

        property :id, getter: -> (*) { journal.id }, render_nil: true
        property :user_id, render_nil: true
        property :user_name, getter: -> (*) { journal.user.try(:name) }, render_nil: true
        property :user_login, getter: -> (*) { journal.user.try(:login) }, render_nil: true
        property :user_mail, getter: -> (*) { journal.user.try(:mail) }, render_nil: true
        property :user_avatar, getter: -> (*) {  gravatar_image_url(journal.user.try(:mail)) }, render_nil: true
        property :messages, exec_context: :decorator, render_nil: true
        property :version, getter: -> (*) { journal.version }, render_nil: true
        property :created_at, getter: -> (*) { journal.created_at.utc.iso8601 }, render_nil: true

        def _type
          if represented.journal.notes.blank?
            'Activity'
          else
            'Activity::Comment'
          end
        end

        def messages
          journal = represented.journal
          if journal.notes.blank?
            journal.details.map{ |d| journal.render_detail(d, no_html: true) }
          else
            [journal.notes]
          end
        end
      end
    end
  end
end
