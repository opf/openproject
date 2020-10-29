module Cell::Util
  def util
    Inflector
  end

  class Inflector
    # copied from ActiveSupport.
    def self.underscore(constant)
      constant.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end

    # WARNING: this API might change.
    def self.constant_for(name)
      class_name = name.split("/").collect do |part|
        part.split('_').collect(&:capitalize).join
      end.join('::')
      
      Object.const_get(class_name, false)
    end
  end
end
