require "disposable/version"
require "disposable/twin"
require "disposable/rescheme"

module Disposable
  class Twin
    autoload :Composition,  "disposable/twin/composition"
    autoload :Expose,       "disposable/twin/composition"
  end
end