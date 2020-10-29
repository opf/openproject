# frozen_string_literal: true

basedir = __dir__

require "#{basedir}/lib/prawn/version"

Gem::Specification.new do |spec|
  spec.name = 'prawn'
  spec.version = Prawn::VERSION
  spec.platform = Gem::Platform::RUBY
  spec.summary = 'A fast and nimble PDF generator for Ruby'

  spec.cert_chain = ['certs/pointlessone.pem']
  if $PROGRAM_NAME.end_with? 'gem'
    spec.signing_key = File.expand_path('~/.gem/gem-private_key.pem')
  end

  spec.files = Dir.glob('{examples,lib,spec,manual}/**/**/*') +
    Dir.glob('data/fonts/{MustRead.html,*.afm}') +
    [
      'Rakefile', 'prawn.gemspec', 'Gemfile',
      'COPYING', 'LICENSE', 'GPLv2', 'GPLv3',
      '.yardopts'
    ]
  spec.require_path = 'lib'
  spec.required_ruby_version = '~> 2.5'
  spec.required_rubygems_version = '>= 1.3.6'

  spec.authors = [
    'Gregory Brown', 'Brad Ediger', 'Daniel Nelson', 'Jonathan Greenberg',
    'James Healy'
  ]
  spec.email = [
    'gregory.t.brown@gmail.com', 'brad@bradediger.com', 'dnelson@bluejade.com',
    'greenberg@entryway.net', 'jimmy@deefa.com'
  ]
  spec.licenses = %w[PRAWN GPL-2.0 GPL-3.0]

  spec.add_dependency('pdf-core', '~> 0.8.1')
  spec.add_dependency('ttfunk', '~> 1.6')

  spec.add_development_dependency('pdf-inspector', '>= 1.2.1', '< 2.0.a')
  spec.add_development_dependency('pdf-reader', ['~> 1.4', '>= 1.4.1'])
  spec.add_development_dependency('prawn-manual_builder', '>= 0.3.0')
  spec.add_development_dependency('rake', '~> 12.0')
  spec.add_development_dependency('rspec', '~> 3.0')
  spec.add_development_dependency('rubocop', '~> 0.84.0')
  spec.add_development_dependency('rubocop-performance', '~> 1.1')
  spec.add_development_dependency('rubocop-rspec', '~> 1.32')
  spec.add_development_dependency('simplecov')
  spec.add_development_dependency('yard')

  spec.homepage = 'http://prawnpdf.org'
  spec.description = <<END_DESC
  Prawn is a fast, tiny, and nimble PDF generator for Ruby
END_DESC
end
