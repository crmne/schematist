# frozen_string_literal: true

module Schematist
  module DSL
    module Conditionals
      def conditions
        @conditions ||= []
      end

      def dependencies
        @dependencies ||= {}
      end

      def dependent(property, &block)
        builder = ConditionalBuilder.new
        builder.instance_eval(&block)

        dependencies[property.to_s] = builder
      end

      def given(**properties, &block)
        raise ArgumentError, "given requires at least one property condition" if properties.empty?

        if_schema = {
          properties: properties.transform_keys(&:to_s).transform_values { |v| coerce_condition(v) },
          required: properties.keys.map(&:to_s)
        }

        then_builder = ConditionalBuilder.new
        else_builder = ConditionalBuilder.new

        context = ConditionalContext.new(then_builder, else_builder)
        context.instance_eval(&block)

        condition = {if: if_schema, then: then_builder.to_schema}
        condition[:else] = else_builder.to_schema unless else_builder.empty?

        conditions << condition
      end

      private

      def merge_conditions(schema, schema_class)
        if schema_class.respond_to?(:conditions) && schema_class.conditions.any?
          if schema_class.conditions.length == 1
            schema.merge!(schema_class.conditions.first)
          else
            schema[:allOf] = schema_class.conditions
          end
        end

        if schema_class.respond_to?(:dependencies) && schema_class.dependencies.any?
          dependent_required = {}
          dependent_schemas = {}

          schema_class.dependencies.each do |property, builder|
            if builder.validations_empty?
              dependent_required[property] = builder.required_fields
            else
              dependent_schemas[property] = builder.to_schema
            end
          end

          schema[:dependentRequired] = dependent_required if dependent_required.any?
          schema[:dependentSchemas] = dependent_schemas if dependent_schemas.any?
        end

        schema
      end

      def coerce_condition(value)
        case value
        when Array then {enum: value}
        when Regexp then {pattern: value.source}
        when Hash then value
        else {const: value}
        end
      end
    end
  end
end
