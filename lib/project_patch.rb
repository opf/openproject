require_dependency 'project'

module ProjectPatch
    def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
    end

    module ClassMethods
    end

    module InstanceMethods

        def velocity
            sprints = Sprint.find(:all,
                :conditions => ["project_id = ? and status in ('closed', 'locked') and not(effective_date is null or sprint_start_date is null)", self.id],
                :order => "effective_date desc",
                :limit => 5)
            return nil if sprints.length == 0

            accepted = 0
            days = 0
            most_recent = nil
            sprints.each {|sprint|
                most_recent ||= sprint.days[-1] 
                days += sprint.days.length
                accepted += (sprint.stories.select{|s| s.status.is_closed && s.story_points}.inject(0){|sum, s| sum + s.story_points}) || 0
            }
            velo = {:date => most_recent,
                    :sprints => sprints.length,
                    :days => days / sprints.length,
                    :velocity => accepted / sprints.length}
            if velo[:velocity] and velo[:velocity] > 0
                velo[:days_per_point] = (velo[:days] * 1.0) / velo[:velocity]
            end
            return velo
        end

    end
end
