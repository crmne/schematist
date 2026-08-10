# frozen_string_literal: true

module Schematist
  module DSL
    class ConditionalBuilder
      def requires(*fields)
        required.concat(fields.map(&:to_s))
      end

      VALIDATES_KEY_MAP = {
        type: :type,
        const: :const,
        enum: :enum,
        not_value: :not,
        min_length: :minLength,
        max_length: :maxLength,
        pattern: :pattern,
        minimum: :minimum,
        maximum: :maximum
      }.freeze

      def validates(field, **options)
        constraints = {}

        options.each do |key, value|
          schema_key = VALIDATES_KEY_MAP[key]
          raise ArgumentError, "unknown validates option: #{key.inspect}" unless schema_key

          case key
          when :type then constraints[:type] = value.to_s
          when :not_value then constraints[:not] = {const: value}
          when :pattern then constraints[:pattern] = value.is_a?(Regexp) ? value.source : value
          else constraints[schema_key] = value
          end
        end

        validations[field.to_s] = constraints
      end

      def to_schema
        schema = {}

        schema[:required] = required if required.any?
        schema[:properties] = validations if validations.any?

        schema
      end

      def empty?
        required.empty? && validations.empty?
      end

      def required_fields
        required.dup
      end

      def validations_empty?
        validations.empty?
      end

      private

      def required
        @required ||= []
      end

      def validations
        @validations ||= {}
      end
    end
  end
end
