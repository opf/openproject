module Backlogs::Burndown
  class SeriesRawData < Hash
    def initialize(*args)
      @collect = args.pop
      @sprint = args.pop
      @project = args.pop
      super(*args)
    end

    attr_reader :collect
    attr_reader :sprint
    attr_reader :project

    def collect_names
      @names ||= @collect.to_a.collect(&:last).flatten
    end

    def out_names
      @out_names ||= ["project_id", "fixed_version_id", "tracker_id", "status_id"]
    end

    def unit_for(name)
      return :hours if @collect[:hours].include? name
      return :points if @collect[:points].include? name
    end

    def collect
      days = sprint.days(nil)
      collected_days = days.sort.select{ |d| d <= Date.today }

      date_hash = {}
      collected_days.each do |date|
        date_hash[date] = 0.0
      end

      collect_names.each do |c|
        self[c] = date_hash.dup
      end

      find_interesting_stories.each do |story|
        collect_for_story story, collected_days
      end
    end

    def collect_for_story(story, collected_days)
      details_by_prop = details_by_property(story)

      details_by_prop.each do |key, value|
        value.sort_by { |d| d.journal.created_on }
      end

      current_prop_index = Hash.new { |hash, key| hash[key] = details_by_prop[key] ? 0 : nil }

      collected_days.each do |date|
        (out_names + collect_names).each do |key|

          current_prop_index[key] = determine_prop_index(key, date, current_prop_index, details_by_prop)

          unless not_to_be_collected?(key, date, details_by_prop, current_prop_index, story)
            self[key][date] += value_for_prop(date, details_by_prop[key], current_prop_index[key], story.send(key)).to_f
          end
        end
      end
    end

    private

    if ActiveRecord::Base.respond_to? :acts_as_journalized
      ######################################################
      # New methods using aaj
      #

      class JournalDetail < ::JournalDetail
        attr_reader :journal

        def initialize(prop_key, old_value, value, journal = nil)
          super(prop_key, old_value, value)
          @journal = journal
        end
      end

      def details_by_property(story)
        details = story.journals.all(:order => "version")[1..-1].map do |journal|
          journal.changes.map do |prop_key, change|
            if collect_names.include?(prop_key) || out_names.include?(prop_key)
              JournalDetail.new(prop_key, change.first, change.last, journal)
            end
          end
        end.flatten.compact

        details.group_by(&:prop_key)
      end

      def find_interesting_stories
        fixed_version_query = "(issues.fixed_version_id = ? OR journals.changes LIKE '%fixed_version_id: - ? - [0-9]+%' OR journals.changes LIKE '%fixed_version_id: - [0-9]+ - ?%')"
        project_id_query = "(issues.project_id = ? OR journals.changes LIKE '%project_id: - ? - [0-9]+%' OR journals.changes LIKE '%project_id: - [0-9]+ - ?%')"

        trackers_string = "(#{collected_trackers.map{|i| "(#{i})"}.join("|")})"
        tracker_id_query = "(issues.tracker_id in (?) OR journals.changes LIKE '%tracker_id: - #{trackers_string} - [0-9]+%' OR journals.changes LIKE '%tracker_id: - [0-9]+ - #{trackers_string}%')"

        stories = Issue.all(:include    => :journals,
                            :conditions => ["#{ fixed_version_query }" +
                                            " AND #{ project_id_query }" +
                                            " AND #{ tracker_id_query }",
                                            sprint.id, sprint.id, sprint.id,
                                            project.id, project.id, project.id,
                                            collected_trackers],
                            :order => "#{Issue.table_name}.id")

        stories.delete_if do |s|
          s.fixed_version_id != sprint.id and
            s.journals.none? { |j| j.changes['fixed_version_id'] && j.changes['fixed_version_id'].first == sprint.id }
        end

        stories.delete_if do |s|
          s.project_id != project.id and
            s.journals.none? { |j| j.changes['project_id'] && j.changes['project_id'].first == project.id }
        end

        stories.delete_if do |s|
          collected_trackers.include?(s.tracker) and
            s.journals.none? { |j| j.changes['tracker_id'] && collected_trackers.map(&:to_s).include?(j.changes['tracker_id'].first.to_s) }
        end

        stories
      end

    else
      ######################################################
      # Old methods using old journals
      #

      def details_by_property(story)
        details = story.journals.sort_by(&:created_on).collect(&:details).flatten.select{ |d| collect_names.include?(d.prop_key) || out_names.include?(d.prop_key)}

        details.group_by { |d| d.prop_key }
      end

      def find_interesting_stories
        Issue.find(:all,
                   :include => {:journals => :details},
                   :conditions => ["(issues.fixed_version_id = ? OR (journal_details.prop_key = 'fixed_version_id' AND (journal_details.old_value = '?' OR journal_details.value = '?'))) " +
                                   " AND (issues.project_id = ? OR (journal_details.prop_key = 'project_id' AND (journal_details.old_value = '?' OR journal_details.value = '?'))) " +
                                   " AND (issues.tracker_id in (?) OR (journal_details.prop_key = 'tracker_id' AND (journal_details.old_value in (?) OR journal_details.value in (?))))",
                                   sprint.id, sprint.id, sprint.id,
                                   project.id, project.id, project.id,
                                   collected_trackers, collected_trackers.map(&:to_s), collected_trackers.map(&:to_s)])
      end
    end

    def collected_trackers
      @collected_trackers ||= Story.trackers << Task.tracker
    end

    def determine_prop_index(key, date, current_prop_index, details_by_prop)
      prop_index = current_prop_index[key]

      until prop_index.nil? ||
            details_by_prop[key][prop_index].journal.created_on.to_date > date ||
            prop_index == details_by_prop[key].size - 1

        prop_index += 1
      end

      prop_index
    end

    def not_to_be_collected?(key, date, details_by_prop, current_prop_index, story)
      ((collect_names.include?(key) &&
        (project.id != value_for_prop(date, details_by_prop["project_id"], current_prop_index["project_id"], story.send("project_id")).to_i ||
        sprint.id != value_for_prop(date, details_by_prop["fixed_version_id"], current_prop_index["fixed_version_id"], story.send("fixed_version_id")).to_i ||
        !collected_trackers.include?(value_for_prop(date, details_by_prop["tracker_id"], current_prop_index["tracker_id"], story.send("tracker_id")).to_i))) ||
      ((key == "story_points") && IssueStatus.find(value_for_prop(date, details_by_prop["status_id"], current_prop_index["status_id"], story.send("status_id"))).is_closed) ||
      ((key == "story_points") && IssueStatus.find(value_for_prop(date, details_by_prop["status_id"], current_prop_index["status_id"], story.send("status_id"))).is_done?(project)) ||
      out_names.include?(key) ||
      collected_from_children?(key, story) ||
      story.created_on.to_date > date)
    end

    def collected_from_children?(key, story)
      key == "remaining_hours" && story.descendants.size > 0
    end

    def value_for_prop(date, details, index, default)
      if details.nil?
        value = default
      elsif date < details[index].journal.created_on.to_date
        value = details[index].old_value
      else
        value = details[index].value
      end

      value
    end
  end
end
