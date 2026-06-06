# frozen_string_literal: true

module RubyLLM
  class Schema
    module DSL
      module SchemaBuilders
        NOT_GIVEN = Object.new.freeze
        METADATA_OPTIONS = {
          title: :title,
          default: :default,
          examples: :examples,
          deprecated: :deprecated,
          read_only: :readOnly,
          write_only: :writeOnly
        }.freeze
        SchemaBlock = Struct.new(:schemas, :keywords, keyword_init: true)

        def string_schema(description: nil, enum: nil, min_length: nil, max_length: nil, pattern: nil, **options, &block)
          metadata = extract_metadata!(options)
          format = options.delete(:format)
          const = options.delete(:const) { NOT_GIVEN }
          content_encoding = options.delete(:content_encoding)
          content_media_type = options.delete(:content_media_type)
          raise_unknown_options!("string", options)
          schema_block = collect_schema_block(&block) if block_given?

          schema = add_const(metadata.merge({
            type: "string",
            enum: enum,
            description: description,
            minLength: min_length,
            maxLength: max_length,
            pattern: pattern,
            format: format,
            contentEncoding: content_encoding,
            contentMediaType: content_media_type
          }.compact), const)

          merge_schema_block_keywords(schema, schema_block)
        end

        def number_schema(description: nil, minimum: nil, maximum: nil, greater_than: nil, less_than: nil, **options)
          metadata = extract_metadata!(options)
          multiple_of = options.delete(:multiple_of)
          const = options.delete(:const) { NOT_GIVEN }
          raise_unknown_options!("number", options)

          add_const(metadata.merge({
            type: "number",
            description: description,
            minimum: minimum,
            maximum: maximum,
            exclusiveMinimum: greater_than,
            exclusiveMaximum: less_than,
            multipleOf: multiple_of
          }.compact), const)
        end

        def integer_schema(description: nil, minimum: nil, maximum: nil, greater_than: nil, less_than: nil, **options)
          metadata = extract_metadata!(options)
          multiple_of = options.delete(:multiple_of)
          const = options.delete(:const) { NOT_GIVEN }
          raise_unknown_options!("integer", options)

          add_const(metadata.merge({
            type: "integer",
            description: description,
            minimum: minimum,
            maximum: maximum,
            exclusiveMinimum: greater_than,
            exclusiveMaximum: less_than,
            multipleOf: multiple_of
          }.compact), const)
        end

        def boolean_schema(description: nil, **options)
          metadata = extract_metadata!(options)
          const = options.delete(:const) { NOT_GIVEN }
          raise_unknown_options!("boolean", options)

          add_const(metadata.merge({type: "boolean", description: description}.compact), const)
        end

        def null_schema(description: nil, **options)
          metadata = extract_metadata!(options)
          const = options.delete(:const) { NOT_GIVEN }
          raise_unknown_options!("null", options)

          add_const(metadata.merge({type: "null", description: description}.compact), const)
        end

        def object_schema(description: nil, of: nil, reference: nil, **options, &block)
          metadata = extract_metadata!(options)
          min_properties = options.delete(:min_properties)
          max_properties = options.delete(:max_properties)
          unevaluated_properties = options.delete(:unevaluated_properties)
          raise_unknown_options!("object", options)

          if reference
            warn "[DEPRECATION] The `reference` option will be deprecated. Please use `of` instead."
            of = reference
          end

          schema = of ? determine_object_reference(of, description) : build_object_schema(description, &block)

          schema.merge!(metadata)
          schema[:unevaluatedProperties] = unevaluated_properties unless unevaluated_properties.nil?
          schema[:minProperties] = min_properties unless min_properties.nil?
          schema[:maxProperties] = max_properties unless max_properties.nil?
          schema
        end

        def array_schema(description: nil, of: nil, **options, &block)
          metadata = extract_metadata!(options)
          min_items = options.delete(:min_items)
          max_items = options.delete(:max_items)
          unevaluated_items = options.delete(:unevaluated_items)
          unique = options.delete(:unique)
          raise_unknown_options!("array", options)

          schema_block = collect_schema_block(&block) if block_given?
          items = determine_array_items(of, schema_block)

          schema = metadata.merge({
            type: "array",
            description: description,
            items: items,
            minItems: min_items,
            maxItems: max_items,
            uniqueItems: unique,
            unevaluatedItems: unevaluated_items
          }.compact)

          merge_schema_block_keywords(schema, schema_block)
        end

        def tuple_schema(description: nil, **options, &block)
          metadata = extract_metadata!(options)
          raise_unknown_options!("tuple", options)

          schema_block = collect_schema_block(&block)
          schemas = schema_block.schemas

          schema = metadata.merge({
            type: "array",
            description: description,
            prefixItems: schemas,
            minItems: schemas.length,
            maxItems: schemas.length
          }.compact)

          merge_schema_block_keywords(schema, schema_block)
        end

        def any_of_schema(description: nil, **options, &block)
          metadata = extract_metadata!(options)
          raise_unknown_options!("any_of", options)

          schema_block = collect_schema_block(&block)

          schema = metadata.merge({
            description: description,
            anyOf: schema_block.schemas
          }.compact)

          merge_schema_block_keywords(schema, schema_block)
        end

        def one_of_schema(description: nil, **options, &block)
          metadata = extract_metadata!(options)
          raise_unknown_options!("one_of", options)

          schema_block = collect_schema_block(&block)

          schema = metadata.merge({
            description: description,
            oneOf: schema_block.schemas
          }.compact)

          merge_schema_block_keywords(schema, schema_block)
        end

        def all_of_schema(description: nil, **options, &block)
          metadata = extract_metadata!(options)
          raise_unknown_options!("all_of", options)

          schema_block = collect_schema_block(&block)

          schema = metadata.merge({
            description: description,
            allOf: schema_block.schemas
          }.compact)

          merge_schema_block_keywords(schema, schema_block)
        end

        def none_of_schema(description: nil, **options, &block)
          metadata = extract_metadata!(options)
          raise_unknown_options!("none_of", options)

          schema_block = collect_schema_block(&block)
          schemas = schema_block.schemas

          schema = metadata.merge({
            description: description,
            not: schemas.one? ? schemas.first : {anyOf: schemas}
          }.compact)

          merge_schema_block_keywords(schema, schema_block)
        end

        private

        def add_const(schema, const)
          schema[:const] = const unless const.equal?(NOT_GIVEN)
          schema
        end

        def extract_metadata!(options)
          METADATA_OPTIONS.each_with_object({}) do |(option, keyword), metadata|
            metadata[keyword] = options.delete(option) if options.key?(option)
          end
        end

        def merge_schema_block_keywords(schema, schema_block)
          return schema unless schema_block

          schema.replace(schema_block.keywords.merge(schema))
        end

        def merge_schema_metadata(schema, schema_class)
          return schema unless schema_class.respond_to?(:schema_metadata)

          schema.replace(schema_class.schema_metadata.merge(schema))
        end

        def merge_core_keywords(schema, schema_class)
          return schema unless schema_class.respond_to?(:schema_core_keywords)

          schema.merge!(schema_class.schema_core_keywords)
        end

        def raise_unknown_options!(type, options)
          return if options.empty?

          raise ArgumentError, "unknown #{type} schema option: #{options.keys.first.inspect}"
        end

        def determine_array_items(of, schema_block = nil)
          return schema_block.schemas.first if schema_block&.schemas&.any?
          return nil if schema_block
          return send("#{of}_schema") if primitive_type?(of)
          return reference(of) if of.is_a?(Symbol)
          return schema_class_to_inline_schema(of) if schema_class?(of)

          raise InvalidArrayTypeError, "Invalid array type: #{of.inspect}. Must be a primitive type (:string, :number, etc.), a symbol reference, a Schema class, or a Schema instance."
        end

        def build_object_schema(description, &block)
          sub_schema = Class.new(Schema)
          result = sub_schema.class_eval(&block)

          return result.merge(description ? {description: description} : {}) if result.is_a?(Hash) && result["$ref"] && sub_schema.properties.empty?
          return schema_class_to_inline_schema(result).merge(description ? {description: description} : {}) if schema_class?(result) && sub_schema.properties.empty?

          schema = {
            type: "object",
            properties: sub_schema.properties,
            required: sub_schema.required_properties,
            additionalProperties: sub_schema.additional_properties,
            description: description
          }.compact

          merge_schema_metadata(schema, sub_schema)
          merge_core_keywords(schema, sub_schema)
          merge_conditions(schema, sub_schema)
          merge_object_keywords(schema, sub_schema)
        end

        def determine_object_reference(of, description = nil)
          result = case of
                   when Symbol
                     reference(of)
                   when Class
                     raise InvalidObjectTypeError, "Invalid object type: #{of.inspect}. Class must inherit from RubyLLM::Schema." unless schema_class?(of)

                     schema_class_to_inline_schema(of)

                   else
                     raise InvalidObjectTypeError, "Invalid object type: #{of.inspect}. Must be a symbol reference, a Schema class, or a Schema instance." unless schema_class?(of)

                     schema_class_to_inline_schema(of)

                   end

          description ? result.merge(description: description) : result
        end

        def collect_schemas_from_block(&block)
          collect_schema_block(&block).schemas
        end

        def collect_schema_block(&block)
          schema_block = SchemaBlock.new(schemas: [], keywords: {})
          schema_builder = self

          context = Object.new

          # Dynamically create methods for all schema builders
          schema_builder.methods.grep(/_schema$/).each do |schema_method|
            type_name = schema_method.to_s.sub(/_schema$/, "")

            context.define_singleton_method(type_name) do |_name = nil, **options, &blk|
              schema_block.schemas << schema_builder.send(schema_method, **options, &blk)
            end
          end

          context.define_singleton_method(:unevaluated_properties) do |value|
            schema_block.keywords[:unevaluatedProperties] = value
          end

          context.define_singleton_method(:unevaluated_items) do |value|
            schema_block.keywords[:unevaluatedItems] = value
          end

          context.define_singleton_method(:contains) do |min: nil, max: nil, &blk|
            schema_block.keywords[:contains] = schema_builder.send(:collect_schemas_from_block, &blk).first
            schema_block.keywords[:minContains] = min unless min.nil?
            schema_block.keywords[:maxContains] = max unless max.nil?
          end

          context.define_singleton_method(:content_schema) do |&blk|
            schema_block.keywords[:contentSchema] = schema_builder.send(:collect_schemas_from_block, &blk).first
          end

          context.define_singleton_method(:description) do |value|
            schema_block.keywords[:description] = value
          end

          METADATA_OPTIONS.each do |method_name, keyword|
            context.define_singleton_method(method_name) do |value|
              schema_block.keywords[keyword] = value
            end
          end

          RubyLLM::Schema::CORE_KEYWORDS.each do |method_name, keyword|
            context.define_singleton_method(method_name) do |value|
              schema_block.keywords[keyword] = value
            end
          end

          # Allow Schema classes to be accessed in the context
          context.define_singleton_method(:const_missing) do |name|
            const_get(name) if const_defined?(name)
          end

          context.instance_eval(&block)
          schema_block
        end

        def schema_class_to_inline_schema(schema_class_or_instance)
          # Handle both Schema classes and Schema instances
          schema_class = if schema_class_or_instance.is_a?(Class)
                           schema_class_or_instance
                         else
                           schema_class_or_instance.class
                         end

          # Directly convert schema class to inline object schema
          {
            type: "object",
            properties: schema_class.properties,
            required: schema_class.required_properties,
            additionalProperties: schema_class.additional_properties
          }.tap do |schema|
            # For instances, prefer instance description over class description
            description = if schema_class_or_instance.is_a?(Class)
                            schema_class.description
                          else
                            schema_class_or_instance.instance_variable_get(:@description) || schema_class.description
                          end

            merge_schema_metadata(schema, schema_class)
            merge_core_keywords(schema, schema_class)
            schema[:description] = description if description

            merge_conditions(schema, schema_class)
            merge_object_keywords(schema, schema_class)
          end
        end
      end
    end
  end
end
