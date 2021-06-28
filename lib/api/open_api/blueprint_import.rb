module API
  module OpenAPI
    module BlueprintImport
      extend self

      def assemble_file(input_path:, output_path:)
        File.open(output_path, "w") do |f|
          f.write read_file(input_path).gsub(/\t/, '    ')
        end
      end

      def read_file(path)
        bp = File.read path

        bp.gsub(include_directive_regex).each do |_match|
          read_file Pathname(path).parent.join($1).to_s
        end
      end

      def include_directive_regex
        @include_directive_regex ||= /\<\!\-\-\s*include\((.*)\)\s*\-\-\>/
      end

      def convert(version: :stable, single_file: false)
        input_file = Rails.application.root.join("docs/api/apiv3-doc-#{version}.apib")
        md_file = Tempfile.new("apibp.md").path
        assemble_file input_path: input_file, output_path: md_file

        spec = YAML.load %x`api-spec-converter -f api_blueprint -t openapi_3 --syntax=yaml #{md_file}`

        add_security! spec
        amend_schemas! spec, apibp: File.read(md_file)

        if !single_file
          split_up_schemas! spec
          split_up_paths! spec
          split_up_tags! spec
        end

        spec
      ensure
        FileUtils.rm_f md_file if File.exist? md_file
      end

      def split_up_schemas!(spec)
        file_path = Rails.application.root.join "docs/api/apiv3/components/schemas"

        FileUtils.mkdir_p file_path.to_s

        new_schemas = spec["components"]["schemas"].map do |name, content|
          identifier = name.underscore
          file_name = "#{identifier}.yml"

          File.open(file_path.join(file_name), "w") do |f|
            f.write "# Schema: #{name}\n"
            f.write content.to_yaml
          end

          [name, { "$ref" => "./components/schemas/#{file_name}"}]
        end

        spec["components"]["schemas"] = new_schemas.to_h
      end

      def split_up_tags!(spec)
        file_path = Rails.application.root.join "docs/api/apiv3/tags"

        FileUtils.mkdir_p file_path.to_s

        new_tags = spec["tags"].map do |value|
          identifier = value["name"].downcase.gsub("&", "and").gsub(" ", "_")
          file_name = "#{identifier}.yml"

          File.open(file_path.join(file_name), "w") do |f|
            f.write value.to_yaml
          end

          { "$ref" => "./tags/#{file_name}"}
        end

        spec["tags"] = new_tags
      end

      def split_up_paths!(spec)
        file_path = Rails.application.root.join "docs/api/apiv3/paths"

        FileUtils.mkdir_p file_path.to_s

        new_paths = spec["paths"].map do |path, content|
          segments = path.sub("/api/v3", "").split("/").reject(&:blank?)

          (0..(segments.size - 1)).each do |i|
            if i > 0 && segments[i].end_with?("id}")
              before = segments[i - 1]
              after = before.singularize
              
              # certain words like 'news' can't be singularized
              if before == after
                segments[i - 1] = "#{before}_item"
              else
                segments[i - 1] = after
              end
            end
          end
          
          identifier = segments.reject { |s| s.end_with?("id}") }.join("_").presence || "root"
          file_name = "#{identifier}.yml"

          File.open(file_path.join(file_name), "w") do |f|
            f.write "# #{path}\n"
            f.write fix_operation_ids!(fix_references!(content.dup, context: spec)).to_yaml
          end

          [path, { "$ref" => "./paths/#{file_name}"}]
        end

        raise "Splitting up into paths failed! Expected same number of paths. " unless new_paths.size == spec["paths"].size

        spec["paths"] = new_paths.to_h
      end

      def fix_operation_ids!(spec)
        spec.each do |key, value|
          if value.is_a? Hash
            fix_operation_ids! value
          elsif key == "operationId"
            spec[key] = spec[key].gsub " ", "_"
          end
        end

        spec
      end

      def fix_references!(spec, context:)
        spec.each do |key, value|
          if value.is_a? Hash
            fix_references! value, context: context
          elsif value.is_a? Array
            spec[key] = value.map { |v| v.is_a?(Hash) ? fix_references!(v.dup, context: context) : v }
          elsif key == "$ref" && value.start_with?("#/components")
            spec[key] = '.' + context.dig(*(value.split("/").drop(1) + ['$ref']))
          end
        end

        spec
      end
      
      def add_security!(spec)
        spec["components"]["securitySchemes"] = {
          "BasicAuth" => {
            "type" => "http",
            "scheme" => "basic"
          }
        }

        spec["security"] = [
          { "BasicAuth" => [] }
        ]
      end

      def amend_schemas!(spec, apibp:)
        schemas = schema_names spec

        spec["tags"].each do |tag|
          schema = schema_from_tag tag, schema_names: schemas

          if schema
            key = schema.keys.first.underscore.split("_").map(&:capitalize).join("_") + "Model"

            spec["components"]["schemas"][key] = schema.values.first
          end
        end

        add_formattable_schema! spec
        add_link_schema! spec

        add_missing_models! spec, apibp: apibp

        spec["components"]["schemas"] = spec["components"]["schemas"].sort.to_h
      end

      def add_formattable_schema!(spec)
        spec["components"]["schemas"]["Formattable"] = {
          "type" => "object",
          "required" => ["format"],
          "properties" => {
            "format" => {
              "type" => "string",
              "enum" => ["plain", "markdown", "custom"],
              "readOnly" => true,
              "description" => "Indicates the formatting language of the raw text",
              "example" => "markdown"
            },
            "raw" => {
              "type" => "string",
              "description" => "The raw text, as entered by the user",
              "example" => "I **am** formatted!"
            },
            "html" => {
              "type" => "string",
              "readOnly" => true,
              "description" => "The text converted to HTML according to the format",
              "example" => "I <strong>am</strong> formatted!"
            }
          },
          "example" => { "format" => "markdown", "raw" => "I am formatted!", "html" => "I am formatted!" }
        }
      end

      def add_link_schema!(spec)
        spec["components"]["schemas"]["Link"] = {
          "type" => "object",
          "required" => ["href"],
          "properties" => {
            "href" => {
              "type" => "string",
              "nullable" => true,
              "description" => "URL to the referenced resource (might be relative)"
            },
            "title" => {
              "type" => "string",
              "description" => "	Representative label for the resource"
            },
            "templated" => {
              "type" => "boolean",
              "default" => false,
              "description" => "If true the href contains parts that need to be replaced by the client"
            },
            "method" => {
              "type" => "string",
              "default" => "GET",
              "description" => "The HTTP verb to use when requesting the resource",
            },
            "payload" => {
              "type" => "string",
              "description" => "The payload to send in the request to achieve the desired result"
            },
            "identifier" => {
              "type" => "string",
              "description" => "	An optional unique identifier to the link object"
            }
          },
          "examples" => [
            { "href" => nil },
            { "href" => "/api/v3/work_packages", "method" => "POST" },
            { "href" => "/api/v3/examples/{example_id}", "templated" => true },
            { "href" => "urn:openproject-org:api:v3:undisclosed" }
          ]
        }
      end

      def add_missing_models!(spec, apibp:)
        lines = apibp.lines.to_a
        model_candidates = lines.select { |l| l.strip.start_with?("## ") && l.strip.end_with?("]") && l.include?("[/") }

        model_candidates.each do |model|
          extract_model_example! spec, model, lines
        end
      end

      def extract_model_example!(spec, heading, lines)
        model_lines = lines
          .drop(lines.index(heading))
          .drop(1)
          .take_while { |l| not l.strip.start_with?("#") }

        return unless model_lines.include? "+ Model\n"

        model_name = heading[(heading.index(" "))..(heading.index("[") - 1)].strip

        json = model_lines
          .drop_while { |l| not l.start_with?(" " * 8) }
          .take_while { |l| l.start_with?(" " * 8) || l.strip.blank? }
          .join
        
        begin
          key = model_name.gsub(" ", "_") + "Model"
          example = JSON.parse json

          spec["components"]["schemas"][key] = Hash(spec["components"]["schemas"][key]).deep_merge({
            "type" => "object",
            "example" => example
          })

          unused_key = key.sub(/Model\Z/, "")

          spec["components"]["schemas"].delete unused_key if spec["components"]["schemas"][unused_key].blank?
        rescue => e
          case model_name
          when 'Markdown', 'Plain Text'
            spec["components"]["schemas"][key] = Hash(spec["components"]["schemas"][key]).deep_merge({
              "type" => "string",
              "format" => "html",
              "example" => json.strip
            })
          else
            STDERR.puts "Failed to parse model example for #{model_name}: #{e.message}"
          end
        end
      end

      def schema_names(spec)
        names = spec["paths"]
          .values
          .flat_map { |p|
            p.values.flat_map { |v| v["tags"] }
          }
          .uniq
          .map(&:singularize)
          .map { |n| n.gsub(" ", "") }
          .reject { |n| n == 'Actions&Capability' }
        
        names << 'ActionsAndCapabilities'

        names
      end

      def schema_from_tag(tag, schema_names:)
        name = tag["name"].singularize.gsub(" ", "")

        return nil unless schema_names.include? name

        {
          name => schema_object(name, tag["description"], schema_names: schema_names)
        }
      end

      def schema_object(name, description, schema_names:)
        properties, required_properties = local_properties description: description, schema_names: schema_names

        actions, _ = link_properties description, heading: "Actions", read_only: true
        links, required_links = link_properties description, heading: "Linked Properties"

        links = Hash(actions).merge Hash(links)

        if links.present?
          properties ||= {}

          properties["_links"] = {
            "type" => "object",
            "required" => required_links,
            "properties" => links
          }
            .reject { |k, v| v.nil? }
        end

        {
          "type" => "object",
          "required" => required_properties,
          "properties" => properties
        }
          .reject { |k, v| v.nil? }
      end

      def link_properties(description, heading:, read_only: nil)
        lines = description
          .lines
          .drop_while { |l| not l =~ /## #{heading}/i }
          .drop_while { |l| not l =~ /\A\|\s*Link\s*\|/ }
          .take_while { |l| l =~ /\A\|/ }
        
        lines.delete_at 1 # delete header line

        data = lines.map { |l| l.split("|")[1..-2].map(&:strip) }

        return nil if data.empty?

        header = data.first
        name_index = header.index "Link"
        desc_index = header.index "Description"
        type_index = header.index "Type"
        cons_index = header.index "Constraints"
        sops_index = header.index "Supported operations"
        cond_index = header.index "Condition"

        required = []

        properties = data[1..-1].map do |row|
          name = row[name_index]
          type = (type_index && String(row[type_index].presence)) || 'object'

          link = {}
          value = {
            "allOf" => [{ "$ref" => "./link.yml" }, link]
          }

          set_description! link, row, desc_index
          set_read_write! link, row, sops_index
          set_constraints! link, row, cons_index

          if !read_only.nil?
            link["readOnly"] = true
          end

          if type_index
            if link["description"].present?
              link["description"] = "#{link['description']}\n\n**Resource**: #{row[type_index]}"
            else
              link["description"] = "**Resource**: #{row[type_index]}"
            end
          end

          required << name if property_required?(row, cons_index)

          add_conditions! link, row, cond_index

          [name, value]
        end

        [properties.to_h, required.presence]
      end

      def local_properties(description:, schema_names:)
        lines = description
          .lines
          .drop_while { |l| not l =~ /## Local Properties/i }
          .drop_while { |l| not l =~ /\A\|\s*Property\s*\|/ }
          .take_while { |l| l =~ /\A\|/ }

        lines.delete_at 1 # delete header line

        data = lines.map { |l| l.split("|")[1..-2].map(&:strip) }

        return nil if data.empty?

        header = data.first
        name_index = header.index "Property"
        desc_index = header.index "Description"
        type_index = header.index "Type"
        cons_index = header.index "Constraints"
        sops_index = header.index "Supported operations"
        cond_index = header.index "Condition"

        required = []

        properties = data[1..-1].map do |row|
          name = row[name_index]
          type = (type_index && String(row[type_index].presence)) || 'object'

          if schema_names.include? type
            next [name, { '$ref' => '#/components/schemas/#{type}' }]
          end

          value = map_type type

          set_description! value, row, desc_index
          set_read_write! value, row, sops_index
          set_constraints! value, row, cons_index

          required << name if property_required?(row, cons_index)

          if name == "language"
            if value.include? "description"
              value["description"] = "#{value['description']} | ISO 639-1 format"
            else
              value["description"] = "ISO 639-1 format"
            end
          end

          add_conditions! value, row, cond_index

          if type == "Formattable"
            value.delete "type"

            value = {
              "allOf" => [
                { "$ref" => "./formattable.yml" },
                value
              ]
            }
          end

          [name, value]
        end

        [properties.to_h, required.presence]
      end

      def type_in_schemas?(type)
        ["formattable"].include? type
      end

      def add_conditions!(data, row, index)
        value = index && String(row[index]).presence

        return unless value

        if data.include? "description"
          data["description"] = "#{data['description']}\n\n# Conditions\n\n#{value}"
        else
          data["description"] = "# Conditions\n\n#{value}"
        end
      end

      def set_constraints!(data, row, index)
        return if index.nil?

        value = String(row[index])
        
        set_minimum! data, value
        set_maximum! data, value
        set_min_max_length! data, value
      end
      
      def set_enum!(data, value)
        return unless value.downcase.strip.starts_with? "in: "

        values = value.split(":").last.strip

        values = "[#{values}]" unless values.starts_with? "["

        data["enum"] = YAML.load values
      end

      def set_min_max_length!(data, value)
        return unless data["type"] == "string"

        if value.downcase.include?('not empty')
          data["minLength"] = 1
        elsif value =~ /(\d+)\s+min\s+length/i
          data["minLength"] = $1.to_i
        elsif value =~ /(\d+)\s+max\s+length/i
          data["maxLength"] = $1.to_i
        end
      end

      def set_minimum!(data, value)
        return unless value =~ /x\s+>(=)?\s+(\d+)/

        data["minimum"] = $2.to_i
        data["exclusiveMinimum"] = true unless $1
      end

      def set_maximum!(data, value)
        return unless value =~ /x\s+<(=)?\s+(\d+)/

        data["maximum"] = $2.to_i
        data["exclusiveMaximum"] = true unless $1
      end

      def property_required?(row, index)
        return false if index.nil?

        String(row[index]).downcase.include? 'not null'
      end

      def set_read_write!(data, row, sops_index)
        return if sops_index.nil?

        value = String(row[sops_index]).downcase

        read = value.include? "read"
        write = value.include? "write"

        if read and not write
          data["readOnly"] = true
        elsif write and not read
          data["writeOnly"] = true
        end
      end

      def set_description!(data, row, index)
        return nil unless index

        value = String(row[index])

        data["description"] = value if value.present?
      end

      def map_type(type)
        value = type.downcase

        case value
        when 'date'
          { 'type' => 'string', 'format' => 'date' }
        when 'datetime'
          { 'type' => 'string', 'format' => 'date-time' }
        when 'url'
          { 'type' => 'string', 'format' => 'uri' }
        when 'duration'
          { 'type' => 'string', 'format' => 'duration' }
        else
          { 'type' => value }
        end
      end
    end
  end
end
