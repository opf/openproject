# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aes_key_wrap/version'

Gem::Specification.new do |spec|
  spec.name          = 'aes_key_wrap'
  spec.version       = AESKeyWrap::VERSION
  spec.authors       = ['Tom Dalling']
  spec.email         = ['tom' + '@tom' + 'dalling.com']

  spec.summary       = %q{A Ruby implementation of AES Key Wrap, a.k.a RFC 3394, a.k.a NIST Key Wrap.}
  spec.homepage      = 'https://github.com/tomdalling/aes_key_wrap'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'test_bench', '~> 1.0'
  spec.add_development_dependency 'gem-release'

  # code climate doesn't support v0.18+
  # see: https://github.com/codeclimate/test-reporter/issues/413
  spec.add_development_dependency 'simplecov', '< 0.18'
end

