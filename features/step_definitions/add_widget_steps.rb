When /^I select "(.+)" from the available widgets drop down$/ do |widget_name|
  steps %{When I select "#{widget_name}" from "block-select"}
end

Then /^"(.+)" should be disabled in the available widgets drop down$/ do |widget_name|
  option_name = MyProjectsOverviewsController::BLOCKS.detect{|k, v| I18n.t(v) == widget_name}.first

  steps %Q{Then the "block-select" drop-down should have the following options disabled:
            | #{option_name} |}
end
