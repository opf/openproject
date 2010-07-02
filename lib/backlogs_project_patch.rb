require_dependency 'project'

module Backlogs
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
            score = []
  
            backlog = Story.product_backlog(self)[0,10]
  
            if backlog.length == 0
                score << l(:product_backlog_empty)
            elsif backlog.inject(true) {|unsized, story| unsized && story.story_points.nil? }
                score << l(:product_backlog_unsized)
            else
                score << nil
            end
  
            active = self.active_sprint
            if active
                stats[:active_sprint] = active
                score <<
                    (Issue.exists?(["id <> root_id and estimated_hours is NULL and fixed_version_id =? and tracker_id = ?", active.id, Task.tracker]) ?
                    l(:active_sprint_unsized_stories) : nil)
                score << (
                    Issue.exists?(["id <> root_id and estimated_hours is NULL and fixed_version_id = ? and tracker_id = ?", active.id, Task.tracker]) ?
                    l(:active_sprint_unestimated_tasks) : nil)
                score << (!active.activity ? l(:active_sprint_dormant) : nil)
            end
  
            ## base sprint stats on the last 5 closed sprints
            sprints = Sprint.find(:all,
                :conditions => ["project_id = ? and status in ('closed', 'locked') and not(effective_date is null or sprint_start_date is null)", self.id],
                :order => "effective_date desc",
                :limit => 5)
            planned_velocity = nil
            if sprints.length == 0
                stats[:sprints] = []
            else
                stats[:sprints] = sprints
  
                sprint_ids = sprints.collect{|s| "#{s.id}"}.join(',')
                story_trackers = Story.trackers.collect{|s| "#{s.object_id}"}.join(',')
  
                score << (
                    Issue.exists?(["id = root_id and story_points is NULL and fixed_version_id in (#{sprint_ids}) and tracker_id in (?)", Story.trackers]) ?
                    l(:unsized_stories, {:sprints => sprints.length}) : nil)
  
                score << (
                    Issue.exists?(["id <> root_id and estimated_hours is NULL and fixed_version_id in (#{sprint_ids}) and tracker_id = ?", Task.tracker]) ?
                    l(:unestimated_tasks, {:sprints => sprints.length}) : nil)
  
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
                    pph_variance = (Integer(100 * (pph_diff / pph_count)) - 100).abs
                    score << (pph_variance > 10 ? l(:size_accuracy, {:pct => pph_variance}) : nil)
                end
  
                last_sprint = sprints[-1]
                score << (last_sprint.effective_date < -7.days.from_now.to_date ? l(:project_dormant) : nil) if !active
                score << (!last_sprint.has_wiki_page ?  l(:sprint_notes_missing) : nil)
  
                stats[:average_days_per_sprint] = days / sprints.length
                stats[:velocity] = accepted / sprints.length
                planned_velocity = committed / sprints.length
                stats[:days_per_point] = (stats[:average_days_per_sprint] * 1.0) / stats[:velocity] if stats[:velocity] > 0
            end
  
            stats[:velocity] ||= 0
            score << (stats[:velocity] == 0 ? l(:no_velocity) : nil)
  
            if stats[:velocity] > 0
                planned_velocity ||= 0
                mood = Integer((100.0 * planned_velocity) / stats[:velocity]) - 100
                if mood > 10
                    score << l(:optimistic_velocity, {:pct => mood})
                elsif mood < -10
                    score << l(:pessimistic_velocity, {:pct => mood})
                else
                    score << nil
                end
            end
  
            stats[:score] = {
                :score => (10 * (score.size - score.compact.size)) / score.size,
                :errors => score.compact
            }
            @scrum_statistics = stats
            return @scrum_statistics
        end
  
    end
  end
end

Project.send(:include, Backlogs::ProjectPatch) unless Project.included_modules.include? Backlogs::ProjectPatch
