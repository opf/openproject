# frozen_string_literal: true

module TestManagement
  module Assistant
    module Sources
      # Subject, description, acceptance criteria (custom fields whose name contains
      # "acceptance", any language-independent pattern can be added later) and the visible
      # children of a work package the user can see.
      class WorkPackage
        MAX_CHILDREN = 20
        CHILD_DESCRIPTION_CHARS = 1_000
        ACCEPTANCE_FIELD = /acceptance|akzeptanz|критері/i

        def initialize(user:, work_package_id:)
          @user = user
          @work_package_id = work_package_id
        end

        def work_package
          return @work_package if defined?(@work_package)

          @work_package = ::WorkPackage.visible(@user).find_by(id: @work_package_id.to_s.delete_prefix("#").to_i)
        end

        def material
          wp = work_package
          raise Error, I18n.t("test_management.assistant.errors.work_package_not_found") unless wp

          parts = ["Work package ##{wp.id}#{" (#{wp.type.name})" if wp.respond_to?(:type) && wp.type}: #{wp.subject}"]
          parts << "Description:\n#{wp.description}" if wp.description.present?
          criteria = acceptance_criteria(wp)
          parts << "Acceptance criteria:\n#{criteria.join("\n")}" if criteria.any?
          children = visible_children(wp)
          if children.any?
            child_lines = children.map do |child|
              line = "- ##{child.id} #{child.subject}"
              if child.description.present?
                "#{line}\n  #{Prompt.truncate(child.description.to_s, CHILD_DESCRIPTION_CHARS)}"
              else
                line
              end
            end
            parts << "Child work packages:\n#{child_lines.join("\n")}"
          end
          Material.new(label: "Work package", text: parts.join("\n\n"))
        end

        private

        def acceptance_criteria(work_package)
          return [] unless work_package.respond_to?(:custom_field_values)

          Array(work_package.custom_field_values).filter_map do |value|
            field = value.respond_to?(:custom_field) ? value.custom_field : nil
            next unless field && field.name.to_s.match?(ACCEPTANCE_FIELD) && value.value.present?

            "#{field.name}: #{value.value}"
          end
        rescue StandardError
          []
        end

        def visible_children(work_package)
          ::WorkPackage.visible(@user).where(parent_id: work_package.id).order(:id).limit(MAX_CHILDREN).to_a
        end
      end
    end
  end
end
