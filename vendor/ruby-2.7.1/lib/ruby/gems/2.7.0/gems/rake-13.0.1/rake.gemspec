# -*- encoding: utf-8 -*-
# stub: rake 13.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rake".freeze
  s.version = "13.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.2".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby/rake/issues", "changelog_uri" => "https://github.com/ruby/rake/blob/v13.0.1/History.rdoc", "documentation_uri" => "https://ruby.github.io/rake", "source_code_uri" => "https://github.com/ruby/rake/tree/v13.0.1" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Hiroshi SHIBATA".freeze, "Eric Hodel".freeze, "Jim Weirich".freeze]
  s.bindir = "exe".freeze
  s.date = "2019-11-12"
  s.description = "Rake is a Make-like program implemented in Ruby. Tasks and dependencies are\nspecified in standard Ruby syntax.\nRake has the following features:\n  * Rakefiles (rake's version of Makefiles) are completely defined in standard Ruby syntax.\n    No XML files to edit. No quirky Makefile syntax to worry about (is that a tab or a space?)\n  * Users can specify tasks with prerequisites.\n  * Rake supports rule patterns to synthesize implicit tasks.\n  * Flexible FileLists that act like arrays but know about manipulating file names and paths.\n  * Supports parallel execution of tasks.\n".freeze
  s.email = ["hsbt@ruby-lang.org".freeze, "drbrain@segment7.net".freeze, "".freeze]
  s.executables = ["rake".freeze]
  s.files = [".github/workflows/macos.yml".freeze, ".github/workflows/ubuntu-rvm.yml".freeze, ".github/workflows/ubuntu.yml".freeze, ".github/workflows/windows.yml".freeze, "CONTRIBUTING.rdoc".freeze, "Gemfile".freeze, "History.rdoc".freeze, "MIT-LICENSE".freeze, "README.rdoc".freeze, "Rakefile".freeze, "bin/bundle".freeze, "bin/console".freeze, "bin/rake".freeze, "bin/rdoc".freeze, "bin/rubocop".freeze, "bin/setup".freeze, "doc/command_line_usage.rdoc".freeze, "doc/example/Rakefile1".freeze, "doc/example/Rakefile2".freeze, "doc/example/a.c".freeze, "doc/example/b.c".freeze, "doc/example/main.c".freeze, "doc/glossary.rdoc".freeze, "doc/jamis.rb".freeze, "doc/proto_rake.rdoc".freeze, "doc/rake.1".freeze, "doc/rakefile.rdoc".freeze, "doc/rational.rdoc".freeze, "exe/rake".freeze, "lib/rake.rb".freeze, "lib/rake/application.rb".freeze, "lib/rake/backtrace.rb".freeze, "lib/rake/clean.rb".freeze, "lib/rake/cloneable.rb".freeze, "lib/rake/cpu_counter.rb".freeze, "lib/rake/default_loader.rb".freeze, "lib/rake/dsl_definition.rb".freeze, "lib/rake/early_time.rb".freeze, "lib/rake/ext/core.rb".freeze, "lib/rake/ext/string.rb".freeze, "lib/rake/file_creation_task.rb".freeze, "lib/rake/file_list.rb".freeze, "lib/rake/file_task.rb".freeze, "lib/rake/file_utils.rb".freeze, "lib/rake/file_utils_ext.rb".freeze, "lib/rake/invocation_chain.rb".freeze, "lib/rake/invocation_exception_mixin.rb".freeze, "lib/rake/late_time.rb".freeze, "lib/rake/linked_list.rb".freeze, "lib/rake/loaders/makefile.rb".freeze, "lib/rake/multi_task.rb".freeze, "lib/rake/name_space.rb".freeze, "lib/rake/packagetask.rb".freeze, "lib/rake/phony.rb".freeze, "lib/rake/private_reader.rb".freeze, "lib/rake/promise.rb".freeze, "lib/rake/pseudo_status.rb".freeze, "lib/rake/rake_module.rb".freeze, "lib/rake/rake_test_loader.rb".freeze, "lib/rake/rule_recursion_overflow_error.rb".freeze, "lib/rake/scope.rb".freeze, "lib/rake/task.rb".freeze, "lib/rake/task_argument_error.rb".freeze, "lib/rake/task_arguments.rb".freeze, "lib/rake/task_manager.rb".freeze, "lib/rake/tasklib.rb".freeze, "lib/rake/testtask.rb".freeze, "lib/rake/thread_history_display.rb".freeze, "lib/rake/thread_pool.rb".freeze, "lib/rake/trace_output.rb".freeze, "lib/rake/version.rb".freeze, "lib/rake/win32.rb".freeze, "rake.gemspec".freeze]
  s.homepage = "https://github.com/ruby/rake".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Rake is a Make-like program implemented in Ruby".freeze
end
