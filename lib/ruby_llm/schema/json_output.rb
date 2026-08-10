# frozen_string_literal: true

module RubyLLM
  class Schema
    module JsonOutput
      def to_json_schema
        validate! # Validate schema before generating JSON

        schema_hash = {
          type: "object",
          properties: self.class.properties,
          required: self.class.required_properties,
          additionalProperties: self.class.additional_properties
        }

        schema_hash[:strict] = self.class.strict unless self.class.strict.nil?

        # Only include $defs if there are definitions
        schema_hash["$defs"] = self.class.definitions unless self.class.definitions.empty?

        self.class.send(:merge_schema_keywords, schema_hash, self.class)

        {
          name: @name,
          description: resolve_runtime_values(@description || self.class.description),
          schema: resolve_runtime_values(schema_hash)
        }
      end

      def to_json(*_args)
        validate! # Validate schema before generating JSON string
        JSON.pretty_generate(to_json_schema)
      end

      private

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
