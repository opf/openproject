# frozen_string_literal: true

module TestManagement
  module Milestones
    class SetAttributesService < ::BaseServices::SetAttributes
      private

      def set_attributes(params)
        params = params.to_h.with_indifferent_access
        work_package_ids = params.key?(:work_package_ids) ? params.delete(:work_package_ids) : nil
        %i[parent_id version_id].each { |key| params[key] = params[key].presence if params.key?(key) }

        super

        assign_work_packages(ids_from(work_package_ids)) unless work_package_ids.nil?
      end

      def set_default_attributes(_params)
        model.created_by ||= user if model.new_record?
        model.status ||= "open"
      end

      # Links to work packages the acting user cannot see are kept (the form only shows
      # visible ones, so their absence from the submitted list is not a removal).
      def assign_work_packages(ids)
        links = model.milestone_work_packages
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
