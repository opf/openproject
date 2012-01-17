Then /^the "(.+)" widget should be in the hidden block$/ do |widget_name|
  steps %{Then I should see "#{widget_name}" within "#list-hidden"}
end
