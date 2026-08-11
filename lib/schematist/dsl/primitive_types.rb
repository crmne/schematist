# frozen_string_literal: true

module Schematist
  module DSL
    module PrimitiveTypes
      def string(name = nil, description: nil, required: true, requires: nil, **options, &block)
        add_property_or_self(name, string_schema(description: description, **options, &block), required: required, requires: requires)
      end

      def number(name = nil, description: nil, required: true, requires: nil, **options, &block)
        add_property_or_self(name, number_schema(description: description, **options, &block), required: required, requires: requires)
      end

      def integer(name = nil, description: nil, required: true, requires: nil, **options, &block)
        add_property_or_self(name, integer_schema(description: description, **options, &block), required: required, requires: requires)
      end

      def boolean(name = nil, description: nil, required: true, requires: nil, **options, &block)
        add_property_or_self(name, boolean_schema(description: description, **options, &block), required: required, requires: requires)
      end

      def null(name = nil, description: nil, required: true, requires: nil, **options, &block)
        add_property_or_self(name, null_schema(description: description, **options, &block), required: required, requires: requires)
      end
    end
  end
end
