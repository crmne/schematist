# frozen_string_literal: true

module Schematist
  module DSL
    class ConditionalContext
      def initialize(then_builder, else_builder)
        @then_builder = then_builder
        @else_builder = else_builder
      end

      def otherwise(&block)
        @else_builder.instance_eval(&block)
      end

      # Everything else describes the then branch
      def method_missing(name, ...)
        return super unless @then_builder.respond_to?(name)

        @then_builder.public_send(name, ...)
      end

      def respond_to_missing?(name, include_private = false)
        @then_builder.respond_to?(name) || super
      end
    end
  end
end
