# frozen_string_literal: true

module RubyLLM
  class Schema
    module JsonOutput
      DRAFT_2020_12 = "https://json-schema.org/draft/2020-12/schema"

      # A Draft 2020-12 JSON Schema document, string-keyed and ready for any JSON Schema validator
      def to_json_schema
        validate! # Validate schema before generating JSON

        document = schema_body
        class_description = document.delete(:description)
        header = {
          "$schema" => DRAFT_2020_12,
          title: document.delete(:title) || @name,
          description: @description || class_description
        }.compact

        json_compatible(resolve_runtime_values(header.merge(document)))
      end

      def to_json(*_args)
        validate! # Validate schema before generating JSON string
        JSON.pretty_generate(to_json_schema)
      end

      private

      def schema_body
        schema_hash = {
          type: "object",
          properties: self.class.properties,
          required: self.class.required_properties,
          additionalProperties: self.class.additional_properties
        }

        # Only include $defs if there are definitions
        schema_hash["$defs"] = self.class.definitions unless self.class.definitions.empty?

        self.class.send(:merge_schema_keywords, schema_hash, self.class)

        schema_hash
      end

      # JSON Schema documents are string-keyed. Symbols survive a Ruby comparison but not a JSON round trip.
      def json_compatible(value)
        case value
        when Hash
          value.to_h { |key, nested_value| [key.to_s, json_compatible(nested_value)] }
        when Array
          value.map { |nested_value| json_compatible(nested_value) }
        when Symbol
          value.to_s
        else
          value
        end
      end

      # Values declared as procs are resolved here, so one schema class can render differently per instance
      def resolve_runtime_values(value)
        case value
        when Proc
          resolve_runtime_values(value.arity.zero? ? instance_exec(&value) : value.call(self))
        when Hash
          value.transform_values { |nested_value| resolve_runtime_values(nested_value) }
        when Array
          value.map { |nested_value| resolve_runtime_values(nested_value) }
        else
          value
        end
      end
    end
  end
end
