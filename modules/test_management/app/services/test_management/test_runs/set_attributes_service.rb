# frozen_string_literal: true

module TestManagement
  module TestRuns
    class SetAttributesService < ::BaseServices::SetAttributes
      private

      def set_attributes(params)
        params = params.to_h.with_indifferent_access
        work_package_ids = params.key?(:work_package_ids) ? params.delete(:work_package_ids) : nil
        test_case_ids = params.key?(:test_case_ids) ? params.delete(:test_case_ids) : nil
        selection_suite_ids = params.delete(:selection_suite_ids)
        filter = params.key?(:filter_options) ? params.delete(:filter_options) : nil
        config_ids = params.key?(:configuration_ids) ? params.delete(:configuration_ids) : nil
        params[:milestone_id] = params[:milestone_id].presence if params.key?(:milestone_id)
        params[:test_plan_id] = params[:test_plan_id].presence if params.key?(:test_plan_id)
        params[:test_plan_entry_id] = params[:test_plan_entry_id].presence if params.key?(:test_plan_entry_id)

        super

        model.filter_options = normalize_filter(filter) unless filter.nil?
        assign_configurations(config_ids) unless config_ids.nil?
        assign_selection(test_case_ids, selection_suite_ids)
        assign_work_packages(ids_from(work_package_ids)) unless work_package_ids.nil?
      end

      def set_default_attributes(_params)
        model.author ||= user
        model.state ||= "new"
        model.selection_mode ||= "specific"
      end

      def normalize_filter(raw)
        raw = raw.to_h.with_indifferent_access
        automation = raw[:automation].to_s
        {
          "label_ids" => ids_from(raw[:label_ids]),
          "suite_ids" => ids_from(raw[:suite_ids]),
          "automation" => TestRun::AUTOMATION_FILTERS.include?(automation) ? automation : "any"
        }
      end

      def assign_configurations(raw)
        ids = ids_from(raw)
        model.configuration_ids = ids
        model.configuration_label = Configuration.label_for(ids)
      end

      # Specific selection: chosen cases plus every case in a chosen folder (incl. subfolders).
      def assign_selection(test_case_ids, suite_ids)
        return if test_case_ids.nil? && suite_ids.nil?

        ids = ids_from(test_case_ids)
        folder_ids = ids_from(suite_ids)
        if folder_ids.any? && model.project
          subtree = TestManagement::Suite.subtree_ids(model.project, folder_ids)
          ids |= model.project.tm_test_cases.not_deleted.where(suite_id: subtree).pluck(:id)
        end
        model.selected_case_ids = ids.uniq
      end

      # Links to work packages the acting user cannot see are kept (the form only shows
      # visible ones, so their absence from the submitted list is not a removal).
      def assign_work_packages(ids)
        links = model.test_run_work_packages
        keep = ids | hidden_linked_ids(links)
        links.each { |link| link.mark_for_destruction unless keep.include?(link.work_package_id) }
        (ids - links.map(&:work_package_id)).each { |id| links.build(work_package_id: id) }
      end

      def hidden_linked_ids(links)
        existing = links.reject(&:new_record?).map(&:work_package_id)
        return [] if existing.empty?

        existing - ::WorkPackage.visible(user).where(id: existing).pluck(:id)
      end

      def ids_from(raw)
        Array(raw)
          .flat_map { |value| value.to_s.split(/[\s,]+/) }
          .map { |value| value.delete_prefix("#") }
          .grep(/\A\d+\z/)
          .map(&:to_i)
          .uniq
      end
    end
  end
end
