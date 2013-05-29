FactoryGirl.define do
  factory(:project_association, :class => ProjectAssociation) do
    association(:project_a, :factory => :project)
    association(:project_b, :factory => :project)
  end
end
