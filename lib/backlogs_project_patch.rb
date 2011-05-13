require_dependency 'project'

module Backlogs
  class Statistics
    def initialize
      @errors = {}
      @info = {}
    end

    def merge(stats, prefix = '')
      errors.each {|err|
        err = "#{prefix}#{err}".intern
        stats[err] ||= 0
        stats[err] += 1
      }
      return stats
    end

    def []=(cat, key, *args)
      raise "Unexpected data category #{cat}" unless [:error, :info].include?(cat)

      case args.size
        when 2
          subkey, value = *args
        when 1
          value = args[0]
          subkey = nil
        else
          raise "Unexpected number of argments"
      end

      case cat
        when :error
          if subkey.nil?
            raise "Already reported #{key.inspect}" if @errors.include?(key)
            @errors[key] = value.nil? ? nil : (!!value)

          else
            raise "Already reported #{key.inspect}" if @errors.include?(key) && ! @errors[key].is_a?(Hash)
            @errors[key] ||= {}

            raise "Already errors #{key.inspect}/#{subkey.inspect}" if @errors[key].include?(subkey)
            @errors[key][subkey] = value.nil? ? nil : (!!value)
          end

        when :info
          raise "Already added info #{key.inspect}" if @info.include?(key)
          @info[key] = value
      end
    end

    def score
      scoring = {}
      @errors.each_pair{ |k, v|
        if v.is_a? Hash
          v = v.values.select{|s| !s.nil?}
          scoring[k] = v.select{|s| s}.size == 0 if v.size != 0
        else
          scoring[k] = !v unless v.nil?
        end
      }
      return ((scoring.values.select{|v| v}.size * 10) / scoring.size)
    end

    def scores(prefix='')
      score = {}
      @errors.each_pair{|k, v|
        if v.is_a? Hash
          v.each_pair {|sk, rv|
            score["#{prefix}#{k}_#{sk}".intern] = rv if !rv.blank?
          }
        else
          score["#{prefix}#{k}".intern] = v if !v.blank?
        end
      }
      return score
    end

    def errors(prefix = '')
      score = scores(prefix)
      return score.keys.select{|k| score[k]}
    end

    def info(prefix='')
      info = {}
      @info.each_pair {|k, v|
        info["#{prefix}#{k}".intern] = v
      }
      return info
    end
  end

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
          :conditions => ["project_id = ? and status = 'open' and ? between start_date and effective_date", self.id, Time.now])
      end
    
      def scrum_statistics
        ## pretty expensive to compute, so if we're calling this multiple times, return the cached results
        return @scrum_statistics if @scrum_statistics
  
        @scrum_statistics = Backlogs::Statistics.new
    
        # magic constant
        backlog = Story.product_backlog(self, 10)
        active_sprint = self.active_sprint
        closed_sprints = Sprint.find(:all,
          :conditions => ["project_id = ? and status in ('closed', 'locked') and not(effective_date is null or start_date is null)", self.id],
          :order => "effective_date desc",
          :limit => 5)
        all_sprints = ([active_sprint] + closed_sprints).compact
  
        @scrum_statistics[:info, :active_sprint] = active_sprint
        @scrum_statistics[:info, :closed_sprints] = closed_sprints
  
        @scrum_statistics[:error, :product_backlog, :is_empty] = (self.status == Project::STATUS_ACTIVE && backlog.length == 0)
        @scrum_statistics[:error, :product_backlog, :unsized] = backlog.inject(false) {|unsized, story| unsized || story.story_points.blank? }
  
        @scrum_statistics[:error, :sprint, :unsized] = Issue.exists?(["story_points is null and parent_id is null and fixed_version_id in (?) and tracker_id in (?)", all_sprints.collect{|s| s.id}, Story.trackers])
        @scrum_statistics[:error, :sprint, :unestimated] = Issue.exists?(["estimated_hours is null and not parent_id is null and fixed_version_id in (?) and tracker_id = ?", all_sprints.collect{|s| s.id}, Task.tracker])
        @scrum_statistics[:error, :sprint, :notes_missing] = closed_sprints.inject(false){|missing, sprint| missing || !sprint.has_wiki_page}
  
        @scrum_statistics[:error, :inactive] = (self.status == Project::STATUS_ACTIVE && !(active_sprint && active_sprint.activity))
  
        velocity = nil
        begin
          points = 0
          error = 0
          days = 0
          closed_sprints.each {|sprint|
            bd = sprint.burndown('up')
            accepted = (bd.points_accepted || [0])[-1]
            committed = (bd.points_committed || [0])[0]
            error += (1 - (accepted.to_f / committed.to_f)).abs
  
            points += accepted
            days += bd.ideal.size
          }
          error = (error / closed_sprints.size)
          # magic constant
          @scrum_statistics[:error, :velocity, :varies] = (error > 0.1)
          @scrum_statistics[:error, :velocity, :missing] = false
  
          velocity = (points / closed_sprints.size)
          @scrum_statistics[:info, :velocity_divergance] = error * 100
  
        rescue ZeroDivisionError
          @scrum_statistics[:error, :velocity, :varies] = nil
          @scrum_statistics[:error, :velocity, :missing] = true
  
          @scrum_statistics[:info, :velocity_divergance] = nil
        end
        @scrum_statistics[:info, :velocity] = velocity
  
        if all_sprints.size != 0 && velocity && velocity != 0
          begin
            dps = (all_sprints.inject(0){|d, s| d + s.days.size} / all_sprints.size)
            @scrum_statistics[:info, :average_days_per_sprint] = dps
            @scrum_statistics[:info, :average_days_per_point] = (velocity ? (dps.to_f / velocity) : nil)
          rescue ZeroDivisionError
            dps = nil
          end
        else
          dps = nil
        end

        if dps.nil?
          @scrum_statistics[:info, :average_days_per_sprint] = nil
          @scrum_statistics[:info, :average_days_per_point] = nil
        end
  
        sizing_divergance = nil
        sizing_is_consistent = false
  
        sprint_ids = all_sprints.collect{|s| "#{s.id}"}.join(',')
        story_trackers = Story.trackers.collect{|t| "#{t}"}.join(',')
        if sprint_ids != '' && story_trackers != ''
          select_stories = "
            not (story_points is null or story_points = 0)
            and not (estimated_hours is null or estimated_hours = 0)
            and fixed_version_id in (#{sprint_ids})
            and project_id = #{self.id}
            and not parent_id is null
            and tracker_id in (#{story_trackers})
          "
  
          points_per_hour = Story.find_by_sql("select avg(story_points) / avg(estimated_hours) as points_per_hour from issues where #{select_stories}")[0].points_per_hour
  
          if points_per_hour
            points_per_hour = Float(points_per_hour)
            stories = Story.find(:all, :conditions => [select_stories])
            error = stories.inject(0) {|err, story|
              err + (1 - (points_per_hour / (story.story_points / story.estimated_hours)))
            }
            sizing_divergance = error * 100
            # magic constant
            sizing_is_consistent = (error < 0.1)
          end
        end
        @scrum_statistics[:info, :sizing_divergance] = sizing_divergance
        @scrum_statistics[:error, :sizing_inconsistent] = !sizing_is_consistent
  
        return @scrum_statistics
      end
    
    end
  end
end

Project.send(:include, Backlogs::ProjectPatch) unless Project.included_modules.include? Backlogs::ProjectPatch
