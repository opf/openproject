Gem::Specification.new do |s|
  s.name = 'dynamic_form'
  s.version = '1.0.0'
  s.author = 'David Heinemeier Hansson'
  s.email = 'david@loudthinking.com'
  s.summary = 'Deprecated dynamic form helpers: input, form, error_messages_for, error_messages_on'

  s.add_dependency('rails', '>= 3.0.0')

  s.files = Dir['lib/**/*']
  s.require_path = 'lib'
end
