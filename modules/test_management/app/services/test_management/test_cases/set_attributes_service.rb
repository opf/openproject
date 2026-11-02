# frozen_string_literal: true

module TestManagement
  module TestCases
    class SetAttributesService < ::BaseServices::SetAttributes
      private

      def set_attributes(params)
        params = params.to_h.with_indifferent_access
        work_package_ids = params.key?(:work_package_ids) ? params.delete(:work_package_ids) : nil
        label_names = params.key?(:label_names) ? params.delete(:label_names) : nil

        super
        track_last_editor

        assign_work_packages(normalize_work_package_ids(work_package_ids)) unless work_package_ids.nil?
        assign_labels(normalize_label_names(label_names)) unless label_names.nil?
      end

      # "smoke, regression , Smoke" -> ["smoke", "regression"] (case-insensitive unique).
      # Also accepts an array (e.g. from a multi-select).
      def normalize_label_names(raw)
        Array(raw)
          .flat_map { |value| value.to_s.split(",") }
          .map { |name| TestManagement::Label.normalize_name(name) }
          .compact_blank
          .uniq(&:downcase)
      end

      # Stage label changes in memory (persisted with the case via autosave).
      # Unknown names create new project labels when the case is saved.
      def assign_labels(names)
        links = model.test_case_labels
        wanted = names.map(&:downcase)

        links.each do |link|
          link.mark_for_destruction unless wanted.include?(link.label&.name.to_s.downcase)
        end

        present = links.reject(&:marked_for_destruction?).map { |link| link.label&.name.to_s.downcase }
        names.reject { |name| present.include?(name.downcase) }.each do |name|
          links.build(label: find_or_build_label(name))
        end
      end

      def find_or_build_label(name)
        project = model.project
        existing = project && TestManagement::Label.where(project_id: project.id)
                                                   .where("LOWER(name) = ?", name.downcase).first
        existing || TestManagement::Label.new(project:, name:)
      end

      # "Last edited by/on": every update through the service records the acting
      # user and bumps updated_at (also when only steps or links changed, which
      # would otherwise not touch the test case row). Not set on create, so a
      # never-edited case shows "—".
      def track_last_editor
        return if model.new_record?

        model.change_by_system do
          model.updated_by = user
          model.updated_at = Time.current
        end
      end

      def set_default_attributes(_params)
        model.author ||= user if model.new_record?
        model.status ||= "ready"
        model.priority ||= "medium"
      end

      # Accepts an array (autocompleter posts work_package_ids[]; a leading "" sentinel
      # lets the user clear all links) or a comma/space separated string.
      def normalize_work_package_ids(raw)
        Array(raw)
          .flat_map { |value| value.to_s.split(/[\s,]+/) }
          .map { |value| value.delete_prefix("#") }
          .grep(/\A\d+\z/)
          .map(&:to_i)
          .uniq
      end

      # Stage link changes in memory only. Persisted on save (autosave) after the
      # contract has validated visibility, so an invalid request writes nothing.
      # Links to work packages the acting user cannot see are kept: the form only shows
      # visible ones, so their absence from the submitted list is not a removal.
      def assign_work_packages(ids)
        links = model.test_case_work_packages
        keep = ids | hidden_linked_ids(links)

        links.each do |link|
          link.mark_for_destruction unless keep.include?(link.work_package_id)
        end

        (ids - links.map(&:work_package_id)).each do |id|
          links.build(work_package_id: id)
        end
      end

      def hidden_linked_ids(links)
        existing = links.reject(&:new_record?).map(&:work_package_id)
        return [] if existing.empty?

        existing - ::WorkPackage.visible(user).where(id: existing).pluck(:id)
      end
    end
  end
end
