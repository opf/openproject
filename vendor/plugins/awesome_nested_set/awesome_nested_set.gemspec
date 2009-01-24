Gem::Specification.new do |s|
  s.name = "awesome_nested_set"
  s.version = "1.1.1"
  s.summary = "An awesome replacement for acts_as_nested_set and better_nested_set."
  s.description = s.summary
 
  s.files = %w(init.rb MIT-LICENSE Rakefile README.rdoc lib/awesome_nested_set.rb lib/awesome_nested_set/compatability.rb lib/awesome_nested_set/helper.rb lib/awesome_nested_set/named_scope.rb rails/init.rb test/awesome_nested_set_test.rb test/test_helper.rb test/awesome_nested_set/helper_test.rb test/db/database.yml test/db/schema.rb test/fixtures/categories.yml test/fixtures/category.rb test/fixtures/departments.yml test/fixtures/notes.yml)
 
  s.add_dependency "activerecord", ['>= 1.1']
 
  s.has_rdoc = true
  s.extra_rdoc_files = [ "README.rdoc"]
  s.rdoc_options = ["--main", "README.rdoc", "--inline-source", "--line-numbers"]
 
  s.test_files = %w(test/awesome_nested_set_test.rb test/test_helper.rb test/awesome_nested_set/helper_test.rb test/db/database.yml test/db/schema.rb test/fixtures/categories.yml test/fixtures/category.rb test/fixtures/departments.yml test/fixtures/notes.yml)
  s.require_path = 'lib'
  s.author = "Collective Idea"
  s.email = "info@collectiveidea.com"
  s.homepage = "http://collectiveidea.com"
end
