# frozen_string_literal: true

module Schematist
  class Schema
    extend DSL
    include JsonOutput

    class << self
      def create(&block)
        schema_class = Class.new(Schema)
        schema_class.class_eval(&block)
        schema_class
      end

      def properties
        @properties ||= {}
      end

      def required_properties
        @required_properties ||= []
      end

      def definitions
        @definitions ||= {}
      end

      def name(name = nil)
        @schema_name = name if name
        return @schema_name if defined?(@schema_name)

        super()
      end

      def annotations
        @annotations ||= {}
      end

      def title(*args)
        annotation(:title, *args)
      end

      def description(*args)
        annotation(:description, *args)
      end

      def default(*args)
        annotation(:default, *args)
      end

      def examples(*args)
        annotation(:examples, *args)
      end

      def deprecated(*args)
        annotation(:deprecated, *args)
      end

      def read_only(*args)
        annotation(:read_only, *args)
      end

      def write_only(*args)
        annotation(:write_only, *args)
      end

      def core_keywords
        @core_keywords ||= {}
      end

      def id(*args)
        core_keyword(:id, *args)
      end

      def anchor(*args)
        core_keyword(:anchor, *args)
      end

      def comment(*args)
        core_keyword(:comment, *args)
      end

      def dynamic_anchor(*args)
        core_keyword(:dynamic_anchor, *args)
      end

      def dynamic_ref(*args)
        core_keyword(:dynamic_ref, *args)
      end

      def vocabulary(*args)
        core_keyword(:vocabulary, *args)
      end

      # The schema this class is, when it is not an object built from properties. Set by
      # calling a type without a name: `string enum: %w[a b]` rather than `string :status`.
      def self_schema(definition = nil)
        @self_schema = definition if definition
        @self_schema
      end

      def min_properties(value = nil)
        object_keyword(:minProperties, value)
      end

      def max_properties(value = nil)
        object_keyword(:maxProperties, value)
      end

      def unevaluated_properties(value = nil)
        object_keyword(:unevaluatedProperties, value)
      end

      def unevaluated_items(value = nil)
        object_keyword(:unevaluatedItems, value)
      end

      def additional_properties(value = nil)
        return @additional_properties ||= false if value.nil?

        @additional_properties = value
      end

      def validate!
        validator = Validator.new(self)
        validator.validate!
      end

      def valid?
        validator = Validator.new(self)
        validator.valid?
      end

      private

      def object_keyword(keyword, value)
        return object_keywords[keyword] if value.nil?

        object_keywords[keyword] = value
      end

      def annotation(name, *args)
        read_or_write(annotations, ANNOTATIONS.fetch(name), *args)
      end

      def core_keyword(name, *args)
        read_or_write(core_keywords, CORE_KEYWORDS.fetch(name), *args)
      end

      def read_or_write(store, keyword, *args)
        return store[keyword] if args.empty?

        store[keyword] = args.first
      end
    end

    def initialize(name = nil, description: nil)
      @name = name || self.class.name || "Schema"
      @description = description
    end

    def validate!
      self.class.validate!
    end

    def valid?
      self.class.valid?
    end

    def method_missing(method_name, ...)
      if respond_to_missing?(method_name)
        self.class.send(method_name, ...)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      %i[string number integer boolean array tuple object any_of one_of all_of none_of raw null].include?(method_name) || super
    end
  end
end
