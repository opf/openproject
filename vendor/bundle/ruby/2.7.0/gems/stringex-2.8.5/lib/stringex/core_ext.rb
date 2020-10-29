Stringex = Module.new unless defined?(Stringex)
ensure_module_defined = ->(base, module_name){
  base.const_set(module_name, Module.new) unless base.const_defined?(module_name)
}
ensure_module_defined[Stringex, :StringExtensions]
ensure_module_defined[Stringex::StringExtensions, :PublicInstanceMethods]
ensure_module_defined[Stringex::StringExtensions, :PublicClassMethods]

String.send :include, Stringex::StringExtensions::PublicInstanceMethods
String.send :extend, Stringex::StringExtensions::PublicClassMethods
