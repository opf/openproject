module Timelines
  class WikiMacro
    unloadable

    def apply(content, args, options={})
      timeline = Timelines::Timeline.find_by_id(args[0])

      raise I18n.t('timelines.no_timeline_for_id', :id => args[0].to_s) if timeline.nil?
      raise I18n.t('timelines.no_right_to_view_timeline') unless User.current.allowed_to?(:view_timelines, timeline.project)

      view = options[:view]

      view.render :partial => '/timelines/timelines_timelines/timeline',
                  :locals => {:timeline => timeline}
    end

    private
  end
end
