module OpenProject::Backlogs::Burndown
  class SeriesRawData < Hash
    unloadable

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
      @out_names ||= ["project_id", "fixed_version_id", "type_id", "status_id"]
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

    class JournalDetail < ::JournalDetail
      attr_reader :journal

      def initialize(prop_key, old_value, value, journal = nil)
        super(prop_key, old_value, value)
        @journal = journal
      end
    end

    def details_by_property(story)
      details = story.journals.sort_by(&:version)[1..-1].map do |journal|
        journal.changed_data.map do |prop_key, change|
          if collect_names.include?(prop_key) || out_names.include?(prop_key)
            JournalDetail.new(prop_key, change.first, change.last, journal)
          end
        end
      end.flatten.compact

      details.group_by(&:prop_key)
    end

    def find_interesting_stories
      fixed_version_query = "(#{WorkPackage.table_name}.fixed_version_id = ? OR journals.changed_data LIKE '%fixed_version_id: - ? - [0-9]+%' OR journals.changed_data LIKE '%fixed_version_id: - [0-9]+ - ?%')"
      project_id_query = "(#{WorkPackage.table_name}.project_id = ? OR journals.changed_data LIKE '%project_id: - ? - [0-9]+%' OR journals.changed_data LIKE '%project_id: - [0-9]+ - ?%')"

      types_string = "(#{collected_types.map{|i| "(#{i})"}.join("|")})"
      type_id_query = "(#{WorkPackage.table_name}.type_id in (?) OR journals.changed_data LIKE '%type_id: - #{types_string} - [0-9]+%' OR journals.changed_data LIKE '%type_id: - [0-9]+ - #{types_string}%')"

      stories = WorkPackage.all(:include    => :journals,
                          :conditions => ["#{ fixed_version_query }" +
                                          " AND #{ project_id_query }" +
                                          " AND #{ type_id_query }",
                                          sprint.id, sprint.id, sprint.id,
                                          project.id, project.id, project.id,
                                          collected_types],
                          :order => "#{WorkPackage.table_name}.id")

      stories.delete_if do |s|
        s.fixed_version_id != sprint.id and
          s.journals.none? { |j| j.changed_data['fixed_version_id'] && j.changed_data['fixed_version_id'].first == sprint.id }
      end

      stories.delete_if do |s|
        s.project_id != project.id and
          s.journals.none? { |j| j.changed_data['project_id'] && j.changed_data['project_id'].first == project.id }
      end

      stories.delete_if do |s|
        !collected_types.include?(s.type_id) and
          s.journals.none? { |j| j.changed_data['type_id'] && collected_types.map(&:to_s).include?(j.changed_data['type_id'].first.to_s) }
      end

      stories
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
      (collect_names.include?(key) &&
        not_in_project?(story, date, details_by_prop, current_prop_index) ||
        not_in_sprint?(story, date, details_by_prop, current_prop_index) ||
        not_in_type?(story, date, details_by_prop, current_prop_index)
      ) ||
      ((key == "story_points") && story_is_closed?(story, date, details_by_prop, current_prop_index)) ||
      ((key == "story_points") && story_is_done?(story, date, details_by_prop, current_prop_index)) ||
      out_names.include?(key) ||
      collected_from_children?(key, story) ||
      story.created_at.to_date > date
    end

    def not_in_project?(story, date, details_by_prop, current_prop_index)
      project.id != value_for_prop(date, details_by_prop["project_id"], current_prop_index["project_id"], story.send("project_id")).to_i
    end

    def not_in_sprint?(story, date, details_by_prop, current_prop_index)
        sprint.id != value_for_prop(date, details_by_prop["fixed_version_id"], current_prop_index["fixed_version_id"], story.send("fixed_version_id")).to_i
    end

    def not_in_type?(story, date, details_by_prop, current_prop_index)
      !collected_types.include?(value_for_prop(date, details_by_prop["type_id"], current_prop_index["type_id"], story.send("type_id")).to_i)
    end

    def story_is_closed?(story, date, details_by_prop, current_prop_index)
      work_package_status_by_id(value_for_prop(date, details_by_prop["status_id"], current_prop_index["status_id"], story.send("status_id"))).is_closed
    end

    def story_is_done?(story, date, details_by_prop, current_prop_index)
      work_package_status_done_for_project(value_for_prop(date, details_by_prop["status_id"], current_prop_index["status_id"], story.send("status_id")), project)
    end

    def collected_from_children?(key, story)
      key == "remaining_hours" && story_has_children?(story)
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

    def collected_types
      @collected_types ||= Story.types << Task.type
    end

    def work_package_status_by_id(status_id)
      @work_package_status_by_id ||= Hash.new do |hash, key|
        hash[key] = IssueStatus.find(key)
      end

      @work_package_status_by_id[status_id]
    end

    def work_package_status_done_for_project(status_id, project)
      @work_package_status_done_for_project ||= Hash.new do |hash, key|
        hash[key] = work_package_status_by_id(key).is_done?(project)
      end

      @work_package_status_done_for_project[status_id]
    end

    def story_has_children?(story)

      @story_has_children ||= Hash.new do |hash, key|
        hash[key] = key.children.size > 0
      end

      @story_has_children[story]
    end
  end
end
