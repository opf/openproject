# frozen_string_literal: true

module WorkPackages
  module Shared
    module AssociatedVersions
      private

      def save_associated_versions(work_package)
        persist_associated_versions(work_package)
        sync_version_to_target_versions(work_package) unless work_package.override_target_versions?
      end

      def persist_associated_versions(work_package)
        if work_package.override_target_versions?
          replace_associated_versions(work_package, "target", work_package.target_version_ids_replacements)
        end

        if work_package.override_observed_in_versions?
          replace_associated_versions(work_package, "observed_in", work_package.observed_in_version_ids_replacements)
        end
      end

      def sync_version_to_target_versions(work_package)
        new_ids = work_package.version_id ? [work_package.version_id] : []
        replace_associated_versions(work_package, "target", new_ids)
      end

      def replace_associated_versions(work_package, kind, version_ids)
        work_package.work_package_associated_versions.where(kind:).delete_all

        version_ids.uniq.each do |vid|
          work_package.work_package_associated_versions.create!(version_id: vid, kind:)
        end
      end
    end
  end
end
