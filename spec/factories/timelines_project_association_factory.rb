FactoryGirl.define do
  factory(:timelines_project_association, :class => Timelines::ProjectAssociation) do
    association(:project_a, :factory => :project)
    association(:project_b, :factory => :project)
  end
end
