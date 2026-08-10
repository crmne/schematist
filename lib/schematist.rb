# frozen_string_literal: true

require "json"

require_relative "schematist/version"
require_relative "schematist/errors"

module Schematist
  PRIMITIVE_TYPES = %i[string number integer boolean null].freeze

  # Annotations describe a schema for humans and tools. They carry no validation weight.
  ANNOTATIONS = {
    title: :title,
    description: :description,
    default: :default,
    examples: :examples,
    deprecated: :deprecated,
    read_only: :readOnly,
    write_only: :writeOnly
  }.freeze

  # Core keywords identify a schema and point at other schemas.
  CORE_KEYWORDS = {
    id: "$id",
    anchor: "$anchor",
    comment: "$comment",
    dynamic_anchor: "$dynamicAnchor",
    dynamic_ref: "$dynamicRef",
    vocabulary: "$vocabulary"
  }.freeze
end

# Every file defines the constant its path implies. The DSL modules come before dsl.rb,
# which includes them, and the DSL before schema.rb, which extends it.
require_relative "schematist/dsl/schema_builders"
require_relative "schematist/dsl/primitive_types"
require_relative "schematist/dsl/complex_types"
require_relative "schematist/dsl/conditional_builder"
require_relative "schematist/dsl/conditional_context"
require_relative "schematist/dsl/conditionals"
require_relative "schematist/dsl/utilities"
require_relative "schematist/dsl"
require_relative "schematist/json_output"
require_relative "schematist/validator"
require_relative "schematist/helpers"
require_relative "schematist/schema"
