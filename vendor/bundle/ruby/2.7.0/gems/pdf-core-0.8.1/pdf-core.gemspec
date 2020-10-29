# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'pdf-core'
  spec.version = '0.8.1'
  spec.platform = Gem::Platform::RUBY
  spec.summary = 'PDF::Core is used by Prawn to render PDF documents'
  spec.files =  Dir.glob('lib/**/**/*') +
                %w[COPYING GPLv2 GPLv3 LICENSE] +
                %w[Gemfile Rakefile] +
                ['pdf-core.gemspec']
  spec.require_path = 'lib'
  spec.required_ruby_version = '>= 2.3'
  spec.required_rubygems_version = '>= 1.3.6'

  spec.cert_chain = ['certs/pointlessone.pem']
  if $PROGRAM_NAME.end_with? 'gem'
    spec.signing_key = File.expand_path('~/.gem/gem-private_key.pem')
  end

  # spec.extra_rdoc_files = %w{README.md LICENSE COPYING GPLv2 GPLv3}
  # spec.rdoc_options << '--title' << 'Prawn Documentation' <<
  #                     '--main'  << 'README.md' << '-q'
  spec.authors = [
    'Gregory Brown', 'Brad Ediger', 'Daniel Nelson', 'Jonathan Greenberg',
    'James Healy'
  ]
  spec.email = [
    'gregory.t.brown@gmail.com', 'brad@bradediger.com', 'dnelson@bluejade.com',
    'greenberg@entryway.net', 'jimmy@deefa.com'
  ]
  spec.rubyforge_project = 'prawn'
  spec.licenses = %w[PRAWN GPL-2.0 GPL-3.0]
  spec.add_development_dependency('bundler')
  spec.add_development_dependency('pdf-inspector', '~> 1.1.0')
  spec.add_development_dependency('pdf-reader', '~>1.2')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rubocop', '~> 0.55')
  spec.add_development_dependency('rubocop-rspec', '~> 1.25')
  spec.add_development_dependency('simplecov')
  spec.homepage = 'http://prawn.majesticseacreature.com'
  spec.description = 'PDF::Core is used by Prawn to render PDF documents'
end
