desc "Find potential mass assignment vulnerabilities"
task :find_mass_assignment do
  require File.join(File.dirname(__FILE__), "../find_mass_assignment.rb")
  MassAssignment.find
end
