module OpenProject::Projects
  # @logical_path OpenProject/Projects
  class HoverCardComponentPreview < ViewComponent::Preview
    def playground
      user = FactoryBot.build_stubbed(:admin)
      project = FactoryBot.build_stubbed(:project, :with_status)
      render(::Projects::HoverCardComponent.new(project:, user:))
    end

    def with_hierarchy
      user = FactoryBot.build_stubbed(:admin)
      status = FactoryBot.build_stubbed(:status)
      root = FactoryBot.build_stubbed(:project, name: "Arcanos Flight Planning")
      child = FactoryBot.build_stubbed(:project, name: "Mobile app", parent: root)
      leaf = FactoryBot.build_stubbed(:project, active: false, name: "Data sources", parent: child, status_code: 1)

      chain = [root, child, leaf]

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
