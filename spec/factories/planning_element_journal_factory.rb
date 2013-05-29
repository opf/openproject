PlanningElement # this should fix "uninitialized constant PlanningElementJournal" errors on ci.

FactoryGirl.define do
  factory(:planning_element_journal, :class => PlanningElementJournal) do

    association :journaled, :factory => :planning_element
  end
end
