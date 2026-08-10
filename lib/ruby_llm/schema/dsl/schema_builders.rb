# frozen_string_literal: true

module RubyLLM
  class Schema
    module DSL
      module SchemaBuilders
        # What a schema block yields: the schemas declared in it, and the keywords set on the enclosing node
        SchemaBlock = Struct.new(:schemas, :keywords)

        def string_schema(description: nil, enum: nil, const: nil, min_length: nil, max_length: nil, pattern: nil, format: nil)
          {
            type: "string",
            enum: enum,
            const: const,
            description: description,
            minLength: min_length,
            maxLength: max_length,
            pattern: pattern,
            format: format
          }.compact
        end

        def number_schema(description: nil, minimum: nil, maximum: nil, greater_than: nil, less_than: nil, multiple_of: nil, enum: nil, const: nil)
          {
            type: "number",
            description: description,
            minimum: minimum,
            maximum: maximum,
            exclusiveMinimum: greater_than,
            exclusiveMaximum: less_than,
            multipleOf: multiple_of,
            enum: enum,
            const: const
          }.compact
        end

        def integer_schema(description: nil, minimum: nil, maximum: nil, greater_than: nil, less_than: nil, multiple_of: nil, enum: nil, const: nil)
          {
            type: "integer",
            description: description,
            minimum: minimum,
            maximum: maximum,
            exclusiveMinimum: greater_than,
            exclusiveMaximum: less_than,
            multipleOf: multiple_of,
            enum: enum,
            const: const
          }.compact
        end

        def boolean_schema(description: nil, const: nil)
          {type: "boolean", description: description, const: const}.compact
        end

        def null_schema(description: nil)
          {type: "null", description: description}.compact
        end

        def object_schema(description: nil, of: nil, reference: nil, min_properties: nil, max_properties: nil, unevaluated_properties: nil, &block)
          if reference
            warn "[DEPRECATION] The `reference` option will be deprecated. Please use `of` instead."
            of = reference
          end

          schema = of ? determine_object_reference(of, description) : build_object_schema(description, &block)

          schema.merge!({
            minProperties: min_properties,
            maxProperties: max_properties,
            unevaluatedProperties: unevaluated_properties
          }.compact)
        end

        def array_schema(description: nil, of: nil, min_items: nil, max_items: nil, unique: nil, unevaluated_items: nil, &block)
          schema_block = collect_schema_block(&block) if block

          {
            type: "array",
            description: description,
            items: determine_array_items(of, schema_block),
            minItems: min_items,
            maxItems: max_items,
            uniqueItems: unique,
            unevaluatedItems: unevaluated_items
          }.compact.merge(schema_block ? schema_block.keywords : {})
        end

        def tuple_schema(description: nil, &block)
          schemas = collect_schemas_from_block(&block)

          {
            type: "array",
            description: description,
            prefixItems: schemas,
            minItems: schemas.length,
            maxItems: schemas.length
          }.compact
        end

        def any_of_schema(description: nil, unevaluated_properties: nil, &block)
          schemas = collect_schemas_from_block(&block)

          {
            description: description,
            anyOf: schemas,
            unevaluatedProperties: unevaluated_properties
          }.compact
        end

        def one_of_schema(description: nil, unevaluated_properties: nil, &block)
          schemas = collect_schemas_from_block(&block)

          {
            description: description,
            oneOf: schemas,
            unevaluatedProperties: unevaluated_properties
          }.compact
        end

        def all_of_schema(description: nil, unevaluated_properties: nil, &block)
          schemas = collect_schemas_from_block(&block)

          {
            description: description,
            allOf: schemas,
            unevaluatedProperties: unevaluated_properties
          }.compact
        end

        def none_of_schema(description: nil, unevaluated_properties: nil, &block)
          schemas = collect_schemas_from_block(&block)

          {
            description: description,
            not: schemas.size == 1 ? schemas.first : {anyOf: schemas},
            unevaluatedProperties: unevaluated_properties
          }.compact
        end

        private

        def build_object_schema(description, &block)
          sub_schema = Class.new(Schema)
          result = sub_schema.class_eval(&block)

          # If the block returned a reference and no properties were added, use the reference
          if result.is_a?(Hash) && result["$ref"] && sub_schema.properties.empty?
            result.merge(description ? {description: description} : {})
          # If the block returned a Schema class or instance, convert it to inline schema
          elsif schema_class?(result) && sub_schema.properties.empty?
            schema_class_to_inline_schema(result).merge(description ? {description: description} : {})
          # Block didn't return reference or schema, so we build an inline object schema
          else
            schema = {
              type: "object",
              properties: sub_schema.properties,
              required: sub_schema.required_properties,
              additionalProperties: sub_schema.additional_properties,
              description: description
            }.compact

            merge_schema_keywords(schema, sub_schema)
          end
        end

        def determine_array_items(of, schema_block = nil)
          return schema_block.schemas.first if schema_block
          return send("#{of}_schema") if primitive_type?(of)
          return reference(of) if of.is_a?(Symbol)
          return schema_class_to_inline_schema(of) if schema_class?(of)

          raise InvalidArrayTypeError, "Invalid array type: #{of.inspect}. Must be a primitive type (:string, :number, etc.), a symbol reference, a Schema class, or a Schema instance."
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

        def collect_schemas_from_block(&)
          collect_schema_block(&).schemas
        end

        def collect_schema_block(&block)
          schema_block = SchemaBlock.new([], {})
          schema_builder = self

          context = Object.new

          # Dynamically create methods for all schema builders
          schema_builder.methods.grep(/_schema$/).each do |schema_method|
            type_name = schema_method.to_s.sub(/_schema$/, "")

            context.define_singleton_method(type_name) do |_name = nil, **options, &blk|
              schema_block.schemas << schema_builder.send(schema_method, **options, &blk)
            end
          end

          context.define_singleton_method(:contains) do |min: nil, max: nil, &blk|
            schema_block.keywords.merge!({
              contains: schema_builder.send(:collect_schemas_from_block, &blk).first,
              minContains: min,
              maxContains: max
            }.compact)
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

            schema[:description] = description if description

            merge_schema_keywords(schema, schema_class)
          end
        end
      end
    end
  end
end
