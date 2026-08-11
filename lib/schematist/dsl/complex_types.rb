# frozen_string_literal: true

module Schematist
  module DSL
    module ComplexTypes
      def object(name = nil, description: nil, required: true, requires: nil, **options, &block)
        add_property_or_self(name, object_schema(description: description, **options, &block), required: required, requires: requires)
      end

      def array(name = nil, description: nil, required: true, requires: nil, **options, &block)
        add_property_or_self(name, array_schema(description: description, **options, &block), required: required, requires: requires)
      end

      def tuple(name = nil, description: nil, required: true, requires: nil, **options, &block)
        add_property_or_self(name, tuple_schema(description: description, **options, &block), required: required, requires: requires)
      end

      def any_of(name = nil, description: nil, required: true, requires: nil, **options, &block)
        add_property_or_self(name, any_of_schema(description: description, **options, &block), required: required, requires: requires)
      end

      def one_of(name = nil, description: nil, required: true, requires: nil, **options, &block)
        add_property_or_self(name, one_of_schema(description: description, **options, &block), required: required, requires: requires)
      end

      def all_of(name = nil, description: nil, required: true, requires: nil, **options, &block)
        add_property_or_self(name, all_of_schema(description: description, **options, &block), required: required, requires: requires)
      end

      def none_of(name = nil, description: nil, required: true, requires: nil, **options, &block)
        add_property_or_self(name, none_of_schema(description: description, **options, &block), required: required, requires: requires)
      end

      # Emits a schema fragment verbatim, for the corners of JSON Schema this DSL does not cover
      def raw(name, schema = nil, required: true, requires: nil)
        return self_schema(name) && nil if schema.nil? && name.is_a?(Hash)

        add_property_or_self(name, schema, required: required, requires: requires)
      end

      def optional(name, description: nil, &block)
        any_of(name, description: description) do
          instance_eval(&block)
          null
        end
      end
    end
  end
end
