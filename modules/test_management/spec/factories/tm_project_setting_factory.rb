# frozen_string_literal: true

FactoryBot.define do
  factory :tm_project_setting, class: "TestManagement::ProjectSetting" do
    project
    display_prefix { "TC" }
    folder_tree_layout { "split_pane" }
  end
end
