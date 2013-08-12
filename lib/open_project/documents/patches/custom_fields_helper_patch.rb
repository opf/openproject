module OpenProject
  module Documents
    module CustomFieldsHelperPatch
      def self.included(base)

        base.class_eval do

          def custom_fields_tabs_with_documents
            custom_fields_tabs_without_documents << {:name => 'DocumentCategoryCustomField', :partial => 'custom_fields/index', :label => DocumentCategory::OptionName}
          end

          alias_method_chain :custom_fields_tabs, :documents
        end

      end

    end
  end
end

unless CustomFieldsHelper.included_modules.include?(OpenProject::Documents::CustomFieldsHelperPatch)
  CustomFieldsHelper.send(:include, OpenProject::Documents::CustomFieldsHelperPatch)
end
