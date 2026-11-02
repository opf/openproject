# frozen_string_literal: true

module TestManagement
  # Narrows a project's test cases the way the cases list does:
  #
  # - folder: `suite_id` selects a folder and all its subfolders; "root" selects
  #   unfiled cases (no folder); "deleted" selects soft-deleted cases;
  # - filter: the folder plus the title search (`q`), `status` and `priority`.
  #
  # Shared by the cases list and the cases export, so "Current view" exports
  # exactly what the list shows (deleted view is never exported as "all cases").
  class TestCasesQuery
    SCOPES = %w[project folder filter].freeze
    PARAM_KEYS = %i[suite_id q status priority].freeze

    attr_reader :project, :params

    def initialize(project, params = {}, suites: nil)
      @project = project
      @params = normalize(params)
      @suites = suites
    end

    def suites
      @suites ||= project.tm_suites.to_a
    end

    def unfiled?
      params[:suite_id] == "root"
    end

    def deleted?
      params[:suite_id] == "deleted"
    end

    def folder?
      params[:suite_id].present?
    end

    def filters?
      params[:q].present? || params[:status].present? || params[:priority].present?
    end

    # The selected folder, or nil (no folder selected, unfiled, deleted or unknown id).
    def suite
      return if !folder? || unfiled? || deleted?

      @suite ||= suites.find { |s| s.id.to_s == params[:suite_id].to_s }
    end

    # The narrowest scope that describes the current view.
    def current_scope
      if filters?
        "filter"
      elsif folder?
        "folder"
      else
        "project"
      end
    end

    def results(scope = "filter")
      scope = scope.to_s
      relation = deleted? ? project.tm_test_cases.deleted : project.tm_test_cases.not_deleted
      return relation if scope == "project"
      return apply_search(relation) if deleted?

      relation = apply_folder(relation)
      return relation if scope == "folder"

      apply_attributes(apply_search(relation))
    end

    # IDs of the folder and all its descendants, from the loaded suites.
    def subtree_suite_ids(root)
      children = suites.group_by(&:parent_id)
      ids = []
      queue = [root.id]
      until queue.empty?
        id = queue.shift
        next if ids.include?(id)

        ids << id
        queue.concat(Array(children[id]).map(&:id))
      end
      ids
    end

    # The params that reproduce `scope` (for links), e.g. { suite_id: 3, q: "x" }.
    def params_for(scope)
      case scope.to_s
      when "filter" then params.compact_blank
      when "folder" then params.slice(:suite_id).compact_blank
      else {}
      end
    end

    private

    def normalize(params)
      hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      hash = hash.symbolize_keys.slice(*PARAM_KEYS)
      hash.transform_values { |value| value.is_a?(String) ? value.strip : value&.to_s }
    end

    def apply_folder(relation)
      return relation unless folder?
      return relation.where(suite_id: nil) if unfiled?

      # Unknown folder ids behave like the list always did: nothing but unfiled.
      relation.where(suite_id: suite ? subtree_suite_ids(suite) : nil)
    end

    def apply_search(relation)
      return relation if params[:q].blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
      relation.where("tm_test_cases.title ILIKE ?", pattern)
    end

    def apply_attributes(relation)
      relation = relation.where(status: params[:status]) if params[:status].present?
      relation = relation.where(priority: params[:priority]) if params[:priority].present?
      relation
    end
  end
end
