# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "boolean and raw schemas" do
  let(:schema_class) { Class.new(described_class) }

  it "supports true schemas inside composition" do
    schema_class.any_of :value do
      any_schema
      string
    end

    expect(schema_class.properties[:value]).to eq({
      anyOf: [
        true,
        {type: "string"}
      ]
    })
  end

  it "supports false schemas inside composition" do
    schema_class.none_of :value do
      no_schema
    end

    expect(schema_class.properties[:value]).to eq({
      not: false
    })
  end

  it "supports raw schema properties" do
    schema_class.raw :role, {
      "type" => "string",
      "const" => "admin"
    }

    expect(schema_class.properties[:role]).to eq({
      "type" => "string",
      "const" => "admin"
    })
  end

  it "normalizes symbol keys inside raw schemas" do
    schema_class.raw :payload, {
      type: "object",
      properties: {
        role: {const: "admin"}
      }
    }

    expect(schema_class.properties[:payload]).to eq({
      "type" => "object",
      "properties" => {
        "role" => {"const" => "admin"}
      }
    })
  end

  it "supports anonymous raw schemas inside composition" do
    schema_class.any_of :value do
      raw type: "string", const: "admin"
      integer
    end

    expect(schema_class.properties[:value]).to eq({
      anyOf: [
        {"type" => "string", "const" => "admin"},
        {type: "integer"}
      ]
    })
  end
end
