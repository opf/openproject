# frozen_string_literal: true

module TestManagement
  module Assistant
    # Namespace file for sources/ (Zeitwerk: assistant/sources.rb defines Assistant::Sources;
    # a sources/base.rb would be expected to define Sources::Base and is never autoloaded
    # for Sources::Error, Sources::Material or Sources.for).
    module Sources
      class Error < StandardError; end

      # Source material for Generate, as plain text (fenced as data in the prompt).
      Material = Struct.new(:label, :text, keyword_init: true)

      MAX_TEXT_CHARS = 20_000   # free text / code snippet typed or pasted by the user
      MAX_SOURCE_CHARS = 60_000 # everything sent as source material

      module_function

      def for(generation, user:)
        data = generation.source_data
        case generation.source_type
        when "work_package" then WorkPackage.new(user:, work_package_id: data["work_package_id"]).material
        when "pull_request" then PullRequest.new(project: generation.project, url: data["url"]).material
        when "text" then Material.new(label: "Requirements", text: data["text"].to_s.first(MAX_TEXT_CHARS))
        when "code"
          Material.new(label: "Code#{" (#{data['language']})" if data['language'].present?}",
                       text: data["code"].to_s.first(MAX_TEXT_CHARS))
        else raise Error, "unknown source"
        end
      end
    end
  end
end
