# frozen_string_literal: true

require_relative "schema/version"
require_relative "schema/errors"
require_relative "schema/helpers"
require_relative "schema/validator"
require_relative "schema/dsl"
require_relative "schema/json_output"
require "json"

module RubyLLM
  class Schema
    extend DSL
    include JsonOutput

    PRIMITIVE_TYPES = %i[string number integer boolean null].freeze

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

      def schema_metadata
        @schema_metadata ||= {}
      end

      def name(name = nil)
        @schema_name = name if name
        return @schema_name if defined?(@schema_name)

        super()
      end

      def title(*args)
        metadata_accessor(:title, *args)
      end

      def description(description = nil)
        if description
          @description = description
          schema_metadata[:description] = description
        end

        @description
      end

      def default(*args)
        metadata_accessor(:default, *args)
      end

      def examples(*args)
        metadata_accessor(:examples, *args)
      end

      def deprecated(*args)
        metadata_accessor(:deprecated, *args)
      end

      def read_only(*args)
        metadata_accessor(:readOnly, *args)
      end

      def write_only(*args)
        metadata_accessor(:writeOnly, *args)
      end

      def additional_properties(value = nil)
        return @additional_properties ||= false if value.nil?

        @additional_properties = value
      end

      def strict(*args)
        if args.empty?
          instance_variable_defined?(:@strict) ? @strict : true
        else
          @strict = args.first
        end
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

      def metadata_accessor(keyword, *args)
        return schema_metadata[keyword] if args.empty?

        schema_metadata[keyword] = args.first
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
      %i[string number integer boolean array tuple object any_of one_of all_of none_of null].include?(method_name) || super
    end
  end
end
