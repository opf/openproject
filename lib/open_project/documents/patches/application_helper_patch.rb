module OpenProject
  module Documents
    module ApplicationHelperPatch
      def self.included(base)

        base.class_eval do

          def parse_redmine_links_with_documents(text, project, obj, attr, only_path, options)
            modified = false
            text.gsub!(/([\s\(,\-\[\>]|^)(!)?(([a-z0-9\-_]+):)?(document)((#+|r)(\d+)|(:)([^"\s<>][^\s<>]*?|"[^"]+?"))(?=(?=[[:punct:]]\W)|,|\s|\]|<|$)/) do |m|
              leading, esc, project_prefix, project_identifier, prefix, sep, identifier = $1, $2, $3, $4, $5, $7 || $9, $8 || $10
              link = nil
              if project_identifier
                project = Project.visible.find_by_identifier(project_identifier)
              end
              if esc.nil?
                if sep == '#'
                  oid = identifier.to_i
                  document = Document.visible.find_by_id(oid)
                elsif sep == ':' && project
                  name = identifier.gsub(%r{^"(.*)"$}, "\\1")
                  document = project.documents.visible.find_by_title(name)
                end
                if document
                  link = link_to document.title, {:only_path => only_path, :controller => '/documents', :action => 'show', :id => document},
                                                  :class => 'document'
                end
                modified = true
              end
              leading + (link || "#{project_prefix}#{prefix}#{sep}#{identifier}")
            end
            parse_redmine_links_without_documents(text, project, obj, attr, only_path, options) unless modified
          end

          alias_method_chain :parse_redmine_links, :documents
        end

      end

    end
  end
end

unless ApplicationHelper.included_modules.include?(OpenProject::Documents::ApplicationHelperPatch)
  ApplicationHelper.send(:include, OpenProject::Documents::ApplicationHelperPatch)
end
