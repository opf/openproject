require_dependency 'project'

module ProjectPatch
    def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
    end

    module ClassMethods
    end

    module InstanceMethods

        def active_sprint
            return Sprint.find(:first,
                :conditions => ["project_id = ? and status = 'open' and ? between sprint_start_date and effective_date", self.id, Time.now])
        end

        def scrum_statistics
            ## pretty expensive to compute, so if we're calling this multiple times, return the cached results
            return @scrum_statistics if @scrum_statistics

            stats = {}

            backlog = Story.product_backlog(self)[0,10]
            stats[:backlog_ready] = (backlog.length) > 0 && (backlog.inject(true) {|unprep, story| unprep && !story.story_points.nil? })

            active = self.active_sprint
            stats[:active] = !!active && active.activity

            ## base sprint stats on the last 5 closed sprints
            sprints = Sprint.find(:all,
                :conditions => ["project_id = ? and status in ('closed', 'locked') and not(effective_date is null or sprint_start_date is null)", self.id],
                :order => "effective_date desc",
                :limit => 5)
            if sprints.length != 0
                stats[:sprints] = sprints

                sprint_ids = sprints.collect{|s| "#{s.id}"}.join(',')
                story_trackers = Story.trackers.collect{|s| "#{s.object_id}"}.join(',')
                stats[:has_unsized] = Issue.exists? ["id = root_id and story_points is NULL and fixed_version_id in (#{sprint_ids}) and tracker_id in (?)", Story.trackers]
                stats[:has_unestimated] = Issue.exists? ["id <> root_id and estimated_hours is NULL and fixed_version_id in (#{sprint_ids}) and tracker_id = ?", Task.tracker]

                ## average points per hour over the selected sprints
                points_per_hour = nil
                res = Project.connection.execute("
                    select avg(story_points), avg(estimated_hours)
                    from issues
                    where not story_points is null
                    and fixed_version_id in (#{sprint_ids})
                    and id = root_id
                    and tracker_id in (#{story_trackers})
                    ")
                res.each {|p, h|
                    points_per_hour = ((1.0 * p) / h) if h && h != 0
                }

                accepted = 0
                committed = 0
                days = 0
                pph_count = 0
                pph_diff = 0
                sprints.each {|sprint|
                    days += sprint.days.length
                    bd = sprint.burndown('up')

                    if bd
                        bd[:series][:points_accepted] ||= [0]
                        bd[:series][:points_committed] ||= [0]
                        bd[:series][:remaining_hours] ||= [0]

                        accepted += bd[:series][:points_accepted][-1]
                        committed += bd[:series][:points_committed][0]

                        if points_per_hour && bd[:series][:remaining_hours][0] > 0
                            pph = (1.0 * bd[:series][:points_committed]) / bd[:series][:remaining_hours][0]
                            pph_count += 1
                            pph_diff += (pph - points_per_hour).abs
                        end
                    end
                }
                if points_per_hour and pph_count > 0
                    stats[:points_per_hour_variance] = (pph_diff / pph_count)
                end

                last_sprint = sprints[-1]
                stats[:active] |= (last_sprint.effective_date > -7.days.from_now.to_date)
                stats[:sprint_notes_missing] = !last_sprint.has_wiki_page
                stats[:average_days_per_sprint] = days / sprints.length
                stats[:velocity] = accepted / sprints.length
                stats[:planned_velocity] = committed / sprints.length
                stats[:days_per_point] = (stats[:average_days_per_sprint] * 1.0) / stats[:velocity] if stats[:velocity] > 0
            end

            stats[:velocity] ||= 0
            stats[:planned_velocity] ||= 0
            stats[:velocity_mismatch] = (1 - (stats[:velocity] / stats[:planned_velocity])) if stats[:planned_velocity] > 0

            score = {}
            score[:backlog_ready]           = stats[:backlog_ready]
            score[:has_velocity]            = stats[:velocity] != 0
            score[:plans_velocity]          = stats[:planned_velocity] != 0
            score[:is_active]               = stats[:active]
            score[:all_sized]               = !stats[:has_unsized]
            score[:all_estimated]           = !stats[:has_unestimated]
            score[:stable_sizes]            = stats[:points_per_hour_variance] && stats[:points_per_hour_variance] < 0.1
            score[:has_sprint_notes]        = !stats[:sprint_notes_missing]
            score[:velocity_predictable]    = stats[:planned_velocity] > 0 && stats[:velocity_mismatch].abs < 0.1
            stats[:score] = (10 * score.values.inject(0){|sum, v| sum + (v ?  1 : 0)}) / score.keys.length

            @scrum_statistics = stats
            return @scrum_statistics
        end

    end
end
