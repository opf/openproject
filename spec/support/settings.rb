##
# Runs block with settings specified in options.
# The original settings are restored afterwards.
def with_settings(options, &block)
  saved_settings = options.keys.inject({}) {|h, k| h[k] = Setting[k].dup; h}
  options.each {|k, v| Setting[k] = v}
  yield
ensure
  saved_settings.each {|k, v| Setting[k] = v}
end
