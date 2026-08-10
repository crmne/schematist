# frozen_string_literal: true

module Schematist
  module DSL
    class ConditionalContext
      def initialize(then_builder, else_builder)
        @then_builder = then_builder
        @else_builder = else_builder
      end

      def requires(*fields)
        @then_builder.requires(*fields)
      end

      def validates(field, **options)
        @then_builder.validates(field, **options)
      end

      def otherwise(&block)
        @else_builder.instance_eval(&block)
      end
    end
  end
end
