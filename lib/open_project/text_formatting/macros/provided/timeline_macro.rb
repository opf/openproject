#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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

module OpenProject::TextFormatting::Macros::Provided
  class TimelineMacro < OpenProject::TextFormatting::Macros::MacroBase

    descriptor do
      prefix :opf
      id :timeline
      desc <<-DESC
      Displays the specified timeline.
      DESC
      meta do
        provider 'OpenProject Foundation'
        url 'https://openproject.com'
        issues 'https://community.openproject.com'
        version 'TBD'
      end
      param do
        id :id
        desc <<-DESC
        The id of the timeline.
        DESC
      end
      legacy_support
    end

    def execute(args, **_options)
      unless view.respond_to?(:render)
        raise NotImplementedError, 'Timeline rendering is not supported'
      end

      id = parse_args(args)
      timeline = Timeline.find_by(id: id.to_i)

      raise I18n.t('timelines.no_timeline_for_id', id: id.to_s) if timeline.nil?
      unless User.current.allowed_to?(:view_timelines, timeline.project)
        raise I18n.t('timelines.no_right_to_view_timeline')
      end

      view.render partial: '/timelines/timeline', locals: { timeline: timeline }
    end

    private

    def parse_args(args)
      if args.instance_of?(Hash)
        args[:id]
      else
        args[0]
      end
    end

    register!
  end
end
