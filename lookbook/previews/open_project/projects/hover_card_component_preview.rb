module OpenProject::Projects
  # @logical_path OpenProject/Projects
  class HoverCardComponentPreview < ViewComponent::Preview
    # !! Currently nothing happens when changing the status by
    # !! clicking the options in the dropdown!!
    # @param status select [open, in_progress, completed]
    def playground(status: :open)
      user = FactoryBot.build_stubbed(:admin)
      project = FactoryBot.build_stubbed(:project)
      render(::Projects::HoverCardComponent.new(project:, user:))
    end

    def deep_hierarchy
      user = FactoryBot.build_stubbed(:admin)
      root = FactoryBot.build_stubbed(:project, name: "Company")
      parent = FactoryBot.build_stubbed(:project, name: "Department", parent: root)
      child = FactoryBot.build_stubbed(:project, name: "Team", parent: parent)
      leaf = FactoryBot.build_stubbed(:project, name: "Sprint", parent: child)

      chain = [root, parent, child, leaf]

      chain.each_with_index do |project, i|
        ancestors = chain.first(i)
        %i[visible active].each { |scope| ancestors.define_singleton_method(scope) { |*| self } }
        ancestors.define_singleton_method(:reorder) { |*| self }
        project.define_singleton_method(:ancestors) { ancestors }
      end

      render(::Projects::HoverCardComponent.new(project: leaf, user:))
    end
  end
end
