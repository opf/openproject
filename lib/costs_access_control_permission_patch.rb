require_dependency 'redmine/access_control'

module CostsAccessControlPermissionPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    
    base.class_eval do
      unloadable
      
      # fancy alias_method_chain
      alias_method :initialize_without_inheritance, :initialize
      alias_method :initialize, :initialize_with_inheritance
    end
  end

  module InstanceMethods
    def initialize_with_inheritance(name, hash, options)
      initialize_without_inheritance(name, hash, options)
      if options[:inherits].is_a? Array
        @inherits = options[:inherits].collect{|i| i.is_a?(self.class) ? i.name : i}
      else
        @inherits = []
        if i = options[:inherits]
          @inherits << (i.is_a?(self.class) ? i.name : i)
        end
      end

      g = options[:granular_for]
      @granular_for = (g.is_a? self.class) ? g.name : g
    end
  
    def inherits(recursive = true)
      recursive = (recursive == true)
      @inherits_result ||= {}
      return @inherits_result[recursive] if @inherits_result.has_key?(recursive)
      
      found = (@inherits || []).collect{|i| Redmine::AccessControl.permission(i)}
      granulars = Redmine::AccessControl.permissions.select{|p| p.granular_for == self}
      found += granulars
      
      result = found
      while (found.length > 0) && recursive
        found = found.collect{|p| p.inherits(false)}.flatten - result
        result += found
      end
      @inherits_result[recursive] = result
    end
    
    def inherited_by(recursive = true)
      def parent_perms(perm)
        Redmine::AccessControl.permissions.collect{|p| p if p.inherits(false).detect{|i| i.name == name}}
      end
      
      result = found = parent_perms(self)
      while (found.length > 0) && recursive
        found = found.collect{|p| parent_perms(p)}.flatten - result
        result += found
      end
      result
    end
    
    def granular_for
      @granular_for_obj ||= begin 
        Redmine::AccessControl.permission(@granular_for) if @granular_for
      end
    end

  end
end

Redmine::AccessControl::Permission.send(:include, CostsAccessControlPermissionPatch)