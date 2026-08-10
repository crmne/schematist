# frozen_string_literal: true

require "schematist"

warn <<~DEPRECATION
  [DEPRECATION] ruby_llm-schema is now schematist, and this gem only forwards to it.

    gem 'schematist'                        # was: gem 'ruby_llm-schema'
    class Person < Schematist::Schema; end  # was: RubyLLM::Schema

  Two things the aliases below cannot forward: `strict` is gone, since it is an OpenAI
  response_format flag rather than a JSON Schema keyword, and `to_json_schema` now returns
  a Draft 2020-12 document instead of the provider envelope. See
  https://github.com/crmne/schematist#migrating-from-ruby_llm-schema
DEPRECATION

module RubyLLM
  Schema = Schematist::Schema
  Helpers = Schematist::Helpers
end

# The error hierarchy moved from RubyLLM::Schema::X to Schematist::X. RubyLLM::Schema and
# Schematist::Schema are the same object, so these also become reachable as
# Schematist::Schema::X. Harmless — they are aliases to the very same classes — and it is
# the only way to keep `rescue RubyLLM::Schema::ValidationError` working.
%i[
  Error InvalidSchemaTypeError InvalidArrayTypeError InvalidObjectTypeError
  InvalidSchemaError ValidationError LimitExceededError
].each do |name|
  RubyLLM::Schema.const_set(name, Schematist.const_get(name))
end
