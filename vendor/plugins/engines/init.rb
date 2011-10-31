#-- encoding: UTF-8
# Only call Engines.init once, in the after_initialize block so that Rails
# plugin reloading works when turned on
config.after_initialize do
  Engines.init(initializer) if defined? :Engines
end