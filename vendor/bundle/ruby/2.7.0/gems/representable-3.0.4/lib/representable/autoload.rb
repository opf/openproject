module Representable
  autoload :Hash, 'representable/hash'
  autoload :JSON, 'representable/json'
  autoload :Object, 'representable/object'
  autoload :YAML, 'representable/yaml'
  autoload :XML, 'representable/xml'

  module Hash
    autoload :AllowSymbols, 'representable/hash/allow_symbols'
    autoload :Collection, 'representable/hash/collection'
  end

  autoload :Decorator, 'representable/decorator'
end
