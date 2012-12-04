Then /^the breadcrumb should contain "(.+)"$/ do |string|
  container = ChiliProject::VERSION::MAJOR < 2 ?  "p.breadcrumb a" : "#breadcrumb a"

  steps %Q{ Then I should see "#{string}" within "#{container}" }
end


