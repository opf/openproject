# The code in here, with the exception of the error handling has been copied from the
# activerecord_json_validator gem.

# frozen_string_literal: true

class JsonValidator < ActiveModel::EachValidator
  def initialize(options)
    options.reverse_merge!(schema: nil)
    options.reverse_merge!(options: {})
    @attributes = options[:attributes]

    super

    inject_setter_method(options[:class], @attributes)
  end

  # Validate the JSON value with a JSON schema path or String
  def validate_each(record, attribute, value)
    # Validate value with JSON Schemer
    errors = JSONSchemer.schema(schema(record), **options.fetch(:options)).validate(value).to_a

    # Everything is good if we don’t have any errors and we got valid JSON value
    return if errors.empty? && record.send(:"#{attribute}_invalid_json").blank?

    # Add error message to the attribute
    errors.each do |error|
      add_error(record, error)
    end
  end

  protected

  # Redefine the setter method for the attributes, since we want to
  # catch JSON parsing errors.
  def inject_setter_method(klass, attributes)
    attributes.each do |attribute|
      # rubocop:disable Style/DocumentDynamicEvalDefinition
      klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        attr_reader :"#{attribute}_invalid_json"
        define_method "#{attribute}=" do |args|
          begin
            @#{attribute}_invalid_json = nil
            args = ::ActiveSupport::JSON.decode(args) if args.is_a?(::String)
            super(args)
          rescue ActiveSupport::JSON.parse_error
            @#{attribute}_invalid_json = args
            super({})
          end
        end
      RUBY
      # rubocop:enable Style/DocumentDynamicEvalDefinition
    end
  end

  # Return a valid schema, recursively calling
  # itself until it gets a non-Proc/non-Symbol value.
  def schema(record, schema = nil)
    schema ||= options.fetch(:schema)

    case schema
    when Proc then schema(record, record.instance_exec(&schema))
    when Symbol then schema(record, record.send(schema))
    else schema
    end
  end

  def add_error(record, error)
    data_pointer, type, schema = error.values_at('data_pointer', 'type', 'schema')
    path = data_pointer.split('/', 3)[1..]

    case type
    when 'required'
      add_blank_error(record, error, path)
    when 'null', 'string', 'boolean', 'integer', 'number', 'array', 'object'
      add_type_mismatch_error(record, path, type)
    when 'schema'
      add_schema_violated_error(record, path)
    when 'format'
      add_format_error(record, path, schema.fetch('format'))
    when 'enum'
      add_enum_error(record, path)
    else
      add_invalid_error(record, path)
    end
  end

  def add_blank_error(record, error, path)
    keys = error.dig('details', 'missing_keys')

    keys.each do |key|
      if path.nil?
        record.errors.add(key, :blank)
      else
        record.errors.add(path[0], :blank_nested, property: (path[1..] + [key]).join('/'))
      end
    end
  end

  def add_type_mismatch_error(record, path, type)
    if path.length == 1
      record.errors.add(path[0], :type_mismatch, type:)
    else
      record.errors.add(path[0], :type_mismatch_nested, type:, path: path[1])
    end
  end

  def add_schema_violated_error(record, path)
    if path.length == 1
      record.errors.add(path[0], :unknown_property)
    else
      record.errors.add(path[0], :unknown_property_nested, path: path[1])
    end
  end

  def add_format_error(record, path, expected)
    if path.length == 1
      record.errors.add(path[0], :format, expected:)
    else
      record.errors.add(path[0], :format_nested, expected:, path: path[1])
    end
  end

  def add_enum_error(record, path)
    if path.length == 1
      record.errors.add(path[0], :inclusion)
    else
      record.errors.add(path[0], :inclusion_nested, path: path[1])
    end
  end

  def add_invalid_error(record, path)
    record.errors.add(path[0], :invalid)
  end
end
