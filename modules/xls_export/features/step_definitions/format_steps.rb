Then /^there should be a link to the work package list in ([^ ]+) format( with descriptions)?$/ do |format, with_descriptions|
  path_options = {:project_id => Project.first.identifier, :format => 'xls'}
  path_options[:show_descriptions] = 'true' if with_descriptions
  # Use XPath to match both title and URL, otherwise we might get ambiguous matches
  find(:xpath, "//a[contains(., '#{format}') and " +
                   "@href = '#{project_work_packages_path(path_options)}']")
end
