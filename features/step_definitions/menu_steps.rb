When /^I toggle the "([^"]+)" submenu$/ do |menu_name|
  nodes = all(:css, ".menu_root a[title=\"#{menu_name}\"] .toggler")

  # w/o javascript, all menu elements are expanded by default. So the toggler
  # might not be present.
  nodes.first.click if nodes.present?
end

Then /^there should be no menu item selected$/ do
  page.should_not have_css("#main-menu .selected")
end
