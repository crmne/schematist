# frozen_string_literal: true

module Schematist
  module DSL
    # A branch of a conditional. Backed by a schema class, so anything you can write in a schema
    # you can write in a branch: nested objects, arrays, composition, references, raw fragments.
    # `requires` and `validates` stay as shorthands for the two common cases.
    class ConditionalBuilder
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

      def initialize
        @schema_class = Class.new(Schema)
      end

      # Requires properties without saying anything else about them
      def requires(*fields)
        required.concat(fields.map(&:to_s))
      end

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
        return @schema_class.self_schema.dup if @schema_class.self_schema

        schema = {}
        schema[:properties] = branch_properties if branch_properties.any?
        schema[:required] = branch_required if branch_required.any?
        schema[:additionalProperties] = @schema_class.additional_properties if additional_properties_set?

        @schema_class.send(:merge_schema_keywords, schema, @schema_class)
      end

      def empty?
        to_schema.empty?
      end

      def required_fields
        branch_required
      end

      # A branch that only lists required properties becomes dependentRequired rather than
      # dependentSchemas, which is the smaller thing to say when it is all you mean.
      def validations_empty?
        to_schema.keys == [:required]
      end

      # Everything else is the ordinary schema DSL, evaluated against the branch's schema class
      def method_missing(name, ...)
        return super unless @schema_class.respond_to?(name)

        @schema_class.public_send(name, ...)
      end

      def respond_to_missing?(name, include_private = false)
        @schema_class.respond_to?(name) || super
      end

      private

      def branch_properties
        declared = @schema_class.properties.transform_keys(&:to_s)
        validations.merge(declared)
      end

      def branch_required
        (@schema_class.required_properties.map(&:to_s) + required).uniq
      end

      def additional_properties_set?
        @schema_class.instance_variable_defined?(:@additional_properties)
      end

      def required
        @required ||= []
      end

      def validations
        @validations ||= {}
      end
    end
  end
end
