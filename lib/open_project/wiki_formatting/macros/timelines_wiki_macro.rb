#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module WikiFormatting
    module Macros
      class TimelinesWikiMacro
        unloadable

        def apply(content, args, options={})
          timeline = Timeline.find_by_id(args[0])

          raise I18n.t('timelines.no_timeline_for_id', :id => args[0].to_s) if timeline.nil?
          raise I18n.t('timelines.no_right_to_view_timeline') unless User.current.allowed_to?(:view_timelines, timeline.project)

          view = options[:view]

          view.render :partial => '/timelines/timeline',
                      :locals => {:timeline => timeline}
        end
      end
    end
  end
end
