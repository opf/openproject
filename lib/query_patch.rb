require_dependency 'query'

module QueryPatch
    def self.included(base) # :nodoc:
        base.extend(ClassMethods)

        # Same as typing in the class 
        base.class_eval do
            unloadable # Send unloadable so it will not be unloaded in development
            base.add_available_column(QueryColumn.new(:story_points, :sortable => "#{Issue.table_name}.story_points"))
        end

    end
    
    module ClassMethods
        # Setter for +available_columns+ that isn't provided by the core.
        def available_columns=(v)
            self.available_columns = (v)
        end

        # Method to add a column to the +available_columns+ that isn't provided by the core.
        def add_available_column(column)
            self.available_columns << (column)
        end
    end
end


