# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "object validation keywords" do
  let(:schema_class) { Class.new(described_class) }

  it "supports object property count constraints" do
    schema_class.object :metadata, min_properties: 1, max_properties: 5 do
      string :name
    end

    metadata_schema = schema_class.properties[:metadata]

    expect(metadata_schema[:minProperties]).to eq(1)
    expect(metadata_schema[:maxProperties]).to eq(5)
  end

  it "supports patternProperties with keys_matching" do
    schema_class.object :metadata do
      keys_matching(/^x-/) do
        string
      end

      keys_matching(/^count_/) do
        integer minimum: 0
      end
    end

    expect(schema_class.properties[:metadata][:patternProperties]).to eq({
      "^x-" => {type: "string"},
      "^count_" => {type: "integer", minimum: 0}
    })
  end

  it "supports string patterns with keys_matching" do
    schema_class.object :metadata do
      keys_matching("^x-") do
        string
      end
    end

    expect(schema_class.properties[:metadata][:patternProperties]).to eq({"^x-" => {type: "string"}})
  end

  it "supports propertyNames with keys" do
    schema_class.object :metadata do
      keys do
        string pattern: "^[a-z_]+$"
      end
    end

    expect(schema_class.properties[:metadata][:propertyNames]).to eq({
      type: "string",
      pattern: "^[a-z_]+$"
    })
  end

  it "includes object validation keywords in definitions" do
    schema_class.define :metadata do
      keys_matching(/^x-/) do
        string
      end

      keys do
        string pattern: "^[a-z_]+$"
      end
    end

    definition = schema_class.definitions[:metadata]

    expect(definition[:patternProperties]).to eq({"^x-" => {type: "string"}})
    expect(definition[:propertyNames]).to eq({type: "string", pattern: "^[a-z_]+$"})
  end

  it "includes object validation keywords when embedding schema classes" do
    metadata_schema = Class.new(described_class) do
      keys_matching(/^x-/) do
        string
      end
    end

    schema_class.object :metadata, of: metadata_schema

    expect(schema_class.properties[:metadata][:patternProperties]).to eq({
      "^x-" => {type: "string"}
    })
  end

  it "includes object validation keywords on the root schema" do
    schema_class.keys do
      string pattern: "^[a-z_]+$"
    end

    schema = schema_class.new.to_json_schema

    expect(schema["propertyNames"]).to eq({"type" => "string", "pattern" => "^[a-z_]+$"})
  end
end
