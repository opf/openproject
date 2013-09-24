module OpenProject::Backlogs::Mixins
  module PreventIssueSti
    # overriding ActiveRecord::Inheritance::ClassMethods#sti_name
    # so that stories are stored and found with type-attribute = "WorkPackage"
    def sti_name
      "Issue"
    end

    # overriding ActiveRecord::Inheritance::ClassMethods#find_sti_classes
    # so that stories are instantiated correctly despite sti_name beeing "WorkPackage"
    def find_sti_class(type_name)
      type_name = self.to_s if type_name == "Issue"

      super(type_name)
    end
  end
end
