# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, ".strict" do
  it "outputs strict: true by default" do
    schema = Class.new(RubyLLM::Schema)
    output = schema.new.to_json_schema
    expect(output[:schema][:strict]).to eq(true)
  end

  it "omits strict from output when set to nil" do
    schema = Class.new(RubyLLM::Schema) { strict nil }
    output = schema.new.to_json_schema
    expect(output[:schema]).not_to have_key(:strict)
  end

  it "outputs strict: true when set to true" do
    schema = Class.new(RubyLLM::Schema) { strict true }
    output = schema.new.to_json_schema
    expect(output[:schema][:strict]).to eq(true)
  end

  it "outputs strict: false when set to false" do
    schema = Class.new(RubyLLM::Schema) { strict false }
    output = schema.new.to_json_schema
    expect(output[:schema][:strict]).to eq(false)
  end
end
