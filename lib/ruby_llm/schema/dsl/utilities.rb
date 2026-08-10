# frozen_string_literal: true

module RubyLLM
  class Schema
    module DSL
      module Utilities
        # Schema definition and reference methods
        def define(name, &)
          sub_schema = Class.new(Schema)
          sub_schema.class_eval(&)

          schema = {
            type: "object",
            properties: sub_schema.properties,
            required: sub_schema.required_properties,
            additionalProperties: sub_schema.additional_properties
          }

          merge_schema_keywords(schema, sub_schema)

          definitions[name] = schema
        end

        def object_keywords
          @object_keywords ||= {}
        end

        # Constrains the names of properties matching a pattern, as JSON Schema patternProperties
        def keys_matching(pattern, &block)
          pattern = pattern.source if pattern.is_a?(Regexp)

          object_keywords[:patternProperties] ||= {}
          object_keywords[:patternProperties][pattern] = collect_schemas_from_block(&block).first
        end

        # Constrains every property name, as JSON Schema propertyNames
        def keys(&block)
          object_keywords[:propertyNames] = collect_schemas_from_block(&block).first
        end

        def reference(schema_name)
          if schema_name == :root
            {"$ref" => "#"}
          else
            {"$ref" => "#/$defs/#{schema_name}"}
          end
        end

        private

        # Merges everything a schema class collects beyond its properties: annotations, key constraints, conditionals.
        # Annotations are defaults, so an option passed to the enclosing builder wins over them.
        def merge_schema_keywords(schema, schema_class)
          schema.replace(schema_class.annotations.merge(schema))
          schema.merge!(schema_class.object_keywords)
          merge_conditions(schema, schema_class)
        end

        def add_property(name, definition, required:, requires: nil)
          property_name = name.to_sym

          properties[property_name] = definition
          if required
            required_properties << property_name unless required_properties.include?(property_name)
          else
            required_properties.delete(property_name)
          end

          if requires
            builder = ConditionalBuilder.new
            builder.requires(*Array(requires))
            dependencies[name.to_s] = builder
          end

          nil
        end

        def primitive_type?(type)
          type.is_a?(Symbol) && PRIMITIVE_TYPES.include?(type)
        end

        def schema_class?(type)
          (type.is_a?(Class) && type < Schema) || type.is_a?(Schema)
        end
      end
    end
  end
end
