class Module
  yaml_tag 'tag:ruby.yaml.org,2002:module'

  def self.yaml_new(_klass, _tag, val)
    val.constantize
  end

  def to_yaml(options = {})
    YAML.quick_emit(nil, options) do |out|
      out.scalar(taguri, name, :plain)
    end
  end

  def yaml_tag_read_class(name)
    # Constantize the object so that ActiveSupport can attempt
    # its auto loading magic. Will raise LoadError if not successful.
    name.constantize
    name
  end
end

class Class
  yaml_tag 'tag:ruby.yaml.org,2002:class'
  remove_method :to_yaml if respond_to?(:to_yaml) && method(:to_yaml).owner == Class # use Module's to_yaml
end

class Struct
  def self.yaml_tag_read_class(name)
    # Constantize the object so that ActiveSupport can attempt
    # its auto loading magic. Will raise LoadError if not successful.
    name.constantize
    "Struct::#{name}"
  end
end

module YAML
  def load_dj(yaml)
    # See https://github.com/dtao/safe_yaml
    # When the method is there, we need to load our YAML like this...
    respond_to?(:unsafe_load) ? load(yaml, :safe => false) : load(yaml)
  end
end
