Timelines::PlanningElement # this should fix "uninitialized constant Timelines_PlanningElementJournal" errors on ci.

FactoryGirl.define do
  factory(:timelines_planning_element_journal, :class => Timelines_PlanningElementJournal) do

    association :journaled, :factory => :timelines_planning_element
  end
end
