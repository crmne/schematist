# frozen_string_literal: true

require "json"
require "zeitwerk"

# Both define constants that do not match their path: version.rb has to be loadable on its
# own from the gemspec, and errors.rb holds the whole hierarchy rather than one class.
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

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect("dsl" => "DSL")
loader.ignore("#{__dir__}/schematist/version.rb")
loader.ignore("#{__dir__}/schematist/errors.rb")
loader.ignore("#{__dir__}/tasks")
loader.setup
