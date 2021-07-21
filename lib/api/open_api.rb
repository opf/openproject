module API
  module OpenAPI
    extend self

    def spec
      @spec ||= begin
        spec_path = Rails.application.root.join("docs/api/apiv3/openapi-spec.yml")

        if spec_path.exist?
          assemble_spec spec_path
        else
          raise "Could not find openapi-spec.yml uner #{spec_path}"
        end
      end

      @spec["servers"] = [
        {
          "description" => "This server",
          "url" => "#{Setting.protocol}://#{Setting.host_name}/"
        }
      ]

      @spec
    end

    def assemble_spec(file_path)
      spec = YAML.safe_load File.read(file_path.to_s)

      substitute_refs(spec, path: file_path.parent, root_path: file_path.parent)
    rescue Psych::SyntaxError => e
      raise "Failed to load #{file_path}: #{e.class} #{e.message}"
    end

    def substitute_refs(spec, path:, root_path:, root_spec: spec)
      case spec
      when Hash
        substitute_refs_in_hash spec, path: path, root_path: root_path, root_spec: root_spec
      when Array
        spec.map { |s| substitute_refs s, path: path, root_path: root_path, root_spec: root_spec }
      else
        spec
      end
    end

    def substitute_refs_in_hash(spec, path:, root_path:, root_spec: spec)
      if spec.size == 1 && spec.keys.first == "$ref"
        ref_path = path.join spec.values.first
        ref_value = YAML.safe_load File.read(ref_path.to_s)

        resolve_refs ref_value, path: ref_path.parent, root_path: root_path, root_spec: root_spec
      else
        spec.transform_values { |v| substitute_refs(v, path: path, root_path: root_path, root_spec: root_spec) }
      end
    rescue Psych::SyntaxError => e
      raise "Failed to load #{ref_path}: #{e.class} #{e.message}"
    end

    def resolve_refs(spec, path:, root_path:, root_spec:)
      case spec
      when Hash
        resolve_refs_in_hash spec, path: path, root_path: root_path, root_spec: root_spec
      when Array
        spec.map { |v| resolve_refs v, path: path, root_path: root_path, root_spec: root_spec }
      else
        spec
      end
    end

    def resolve_refs_in_hash(spec, path:, root_path:, root_spec:)
      if spec.size == 1 && spec.keys.first == "$ref"
        resolve_ref spec, path: path, root_path: root_path, root_spec: root_spec
      else
        spec.transform_values { |v| resolve_refs v, path: path, root_path: root_path, root_spec: root_spec }
      end
    end

    def resolve_ref(spec, path:, root_path:, root_spec:)
      ref_path = spec.values.first

      if ref_path.start_with?(".")
        { spec.keys.first => schema_ref(ref_path, path: path, root_path: root_path, root_spec: root_spec) }
      else
        spec
      end
    end

    def schema_ref(ref_path, path:, root_path:, root_spec:)
      name = schema_name ref_path, path: path, root_path: root_path, root_spec: root_spec

      path.join(ref_path).parent.join(name).to_s.sub(root_path.to_s, "#")
    end

    def schema_file(ref_path, path:, root_path:)
      path.join(ref_path).to_s.sub root_path.to_s, "."
    end

    def schema_path(ref_path, path:, root_path:)
      path.join(ref_path).parent.to_s.sub(root_path.to_s, "").split("/").drop 1
    end

    def schema_name(ref_path, path:, root_path:, root_spec:)
      file = schema_file ref_path, path: path, root_path: root_path
      spec_path = schema_path ref_path, path: path, root_path: root_path

      root_spec.dig(*spec_path).find { |_k, v| v["$ref"] == file }.first
    end
  end
end
