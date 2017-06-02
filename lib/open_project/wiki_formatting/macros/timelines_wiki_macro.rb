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

module OpenProject
  module WikiFormatting
    module Macros
      class TimelinesWikiMacro
        def apply(_content, args, options = {})
          timeline = Timeline.find_by(id: args[0])

          raise I18n.t('timelines.no_timeline_for_id', id: args[0].to_s) if timeline.nil?
          raise I18n.t('timelines.no_right_to_view_timeline') unless User.current.allowed_to?(:view_timelines, timeline.project)

          view = options[:view]

          if view.respond_to?(:javascript_include_tag)
            view.render partial: '/timelines/timeline',
                        locals: { timeline: timeline }
          else
            raise NotImplementedError, 'Timeline rendering is not supported'
          end
        end
      end
    end
  end
end
