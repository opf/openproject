# frozen_string_literal: true

module TestManagement
  module Assistant
    # What the chat model gets to know about the project up front, limited to what the user may
    # see: case folders and totals (view_test_cases, implied by use_test_assistant), milestones
    # and recent runs (view_test_runs). Everything else is fetched with read tools.
    class ChatContext
      MAX_FOLDERS = 80
      MAX_MILESTONES = 20
      MAX_RUNS = 10

      def initialize(user:, project:)
        @user = user
        @project = project
      end

      def view_runs?
        @user.allowed_in_project?(:view_test_runs, @project)
      end

      def to_text
        lines = ["Project: #{@project.name}", "Today: #{Date.current.iso8601}"]
        lines.concat(cases_section)
        if view_runs?
          lines.concat(milestones_section)
          lines.concat(runs_section)
        else
          lines << "The user may not see test runs, results or milestones."
        end
        lines.join("\n")
      end

      private

      def cases_section
        cases = @project.tm_test_cases.not_deleted
        by_status = cases.group(:status).count
        counts = cases.where.not(suite_id: nil).group(:suite_id).count
        folders = TestManagement::Suite.where(project_id: @project.id).order(:id).limit(MAX_FOLDERS).to_a
        lines = ["Test cases: #{by_status.values.sum} (#{by_status.map { |s, c| "#{s} #{c}" }.join(', ')})"]
        lines << "Folders (id: path, cases):"
        folders.each { |f| lines << "- #{f.id}: #{f.path_name} (#{counts[f.id].to_i})" }
        lines << "- … more folders not listed" if folders.size == MAX_FOLDERS
        lines
      end

      def milestones_section
        return [] unless TestManagement::ProjectSetting.milestones_enabled?(@project)

        milestones = @project.tm_milestones.ordered.limit(MAX_MILESTONES).to_a
        ["Milestones (id: name, status, due):"] +
          milestones.map { |m| "- #{m.id}: #{m.name}, #{m.status}#{", due #{m.due_date.iso8601}" if m.due_date}" }
      end

      def runs_section
        runs = @project.tm_test_runs.newest_first.limit(MAX_RUNS).to_a
        ["Recent test runs (id: name, state, result counts):"] + runs.map do |run|
          counts = run.status_counts.select { |_, c| c.positive? }.map { |s, c| "#{s} #{c}" }.join(", ")
          "- #{run.id}: #{run.name}, #{run.state}#{", milestone #{run.milestone_id}" if run.milestone_id}, #{counts.presence || 'no cases'}"
        end
      end
    end
  end
end
