# frozen_string_literal: true

module SchemaBuilders
  module_function

  def build_schema_class(&block)
    Class.new(Schematist::Schema) do
      class_eval(&block) if block
    end
  end

  def build_factory_schema(&block)
    Schematist::Schema.create do
      instance_eval(&block) if block
    end
  end

  def build_helper_schema(name = nil, description: nil, &block)
    helper = Object.new
    helper.extend(Schematist::Helpers)
    helper.schema(name, description: description, &block)
  end
end
