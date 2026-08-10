# frozen_string_literal: true

require "spec_helper"

# `strict` is an OpenAI response_format flag, not a JSON Schema keyword, so it is not part of
# the Draft 2020-12 document. It survives only as a class-level accessor for consumers that
# build a provider envelope themselves.
RSpec.describe RubyLLM::Schema, ".strict" do
  it "defaults to true" do
    expect(Class.new(RubyLLM::Schema).strict).to eq(true)
  end

  it "records the configured value" do
    expect(Class.new(RubyLLM::Schema) { strict false }.strict).to eq(false)
    expect(Class.new(RubyLLM::Schema) { strict nil }.strict).to be_nil
  end

  it "stays out of the JSON Schema document" do
    schema = Class.new(RubyLLM::Schema) { strict true }

    expect(schema.new.to_json_schema).not_to have_key("strict")
  end
end
