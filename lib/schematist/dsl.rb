# frozen_string_literal: true

module Schematist
  module DSL
    include SchemaBuilders
    include PrimitiveTypes
    include ComplexTypes
    include Conditionals
    include Utilities
  end
end
