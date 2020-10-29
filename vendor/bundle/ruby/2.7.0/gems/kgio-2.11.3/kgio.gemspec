ENV["VERSION"] or abort "VERSION= must be specified"
manifest = File.readlines('.manifest').map! { |x| x.chomp! }

Gem::Specification.new do |s|
  s.name = %q{kgio}
  s.version = ENV["VERSION"].dup
  s.homepage = 'https://yhbt.net/kgio/'
  s.authors = ['kgio hackers']
  s.description = <<EOF
This is a legacy project, do not use it for new projects.  Ruby
2.3 and later should make this obsolete.  kgio provides
non-blocking I/O methods for Ruby without raising exceptions on
EAGAIN and EINPROGRESS.
EOF
  s.email = %q{kgio-public@yhbt.net}
  s.extra_rdoc_files = IO.readlines('.document').map!(&:chomp!).keep_if do |f|
    File.exist?(f)
  end
  s.files = manifest
  s.summary = 'kinder, gentler I/O for Ruby'
  s.test_files = Dir['test/test_*.rb']
  s.extensions = %w(ext/kgio/extconf.rb)

  s.add_development_dependency('test-unit', '~> 3.0')
  # s.add_development_dependency('strace_me', '~> 1.0') # Linux only

  s.licenses = %w(LGPL-2.1+)
end
