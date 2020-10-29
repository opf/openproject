Gem::Specification.new do |s|
  s.name = 'rinku'
  s.version = '2.0.6'
  s.summary = "Mostly autolinking"
  s.description = <<-EOF
    A fast and very smart autolinking library that
    acts as a drop-in replacement for Rails `auto_link`
  EOF
  s.email = 'vicent@github.com'
  s.homepage = 'https://github.com/vmg/rinku'
  s.authors = ["Vicent Marti"]
  s.license = 'ISC'
  # = MANIFEST =
  s.files = %w[
    COPYING
    README.markdown
    Rakefile
    ext/rinku/autolink.c
    ext/rinku/autolink.h
    ext/rinku/buffer.c
    ext/rinku/buffer.h
    ext/rinku/extconf.rb
    ext/rinku/rinku.c
    ext/rinku/rinku.h
    ext/rinku/rinku_rb.c
    ext/rinku/utf8.c
    ext/rinku/utf8.h
    lib/rails_rinku.rb
    lib/rinku.rb
    rinku.gemspec
    test/autolink_test.rb
  ]
  # = MANIFEST =
  s.test_files = ["test/autolink_test.rb"]
  s.extra_rdoc_files = ["COPYING"]
  s.extensions = ["ext/rinku/extconf.rb"]
  s.require_paths = ["lib"]

  s.add_development_dependency "rake"
  s.add_development_dependency "rake-compiler"
  s.add_development_dependency "minitest", ">= 5.0"

  s.required_ruby_version = '>= 2.0.0'
end
