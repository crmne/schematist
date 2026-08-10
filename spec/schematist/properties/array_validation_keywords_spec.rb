# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "array validation keywords" do
  let(:schema_class) { Class.new(described_class) }

  it "supports uniqueItems with homogeneous arrays" do
    schema_class.array :tags, of: :string, unique: true

    expect(schema_class.properties[:tags]).to eq({
      type: "array",
      items: {type: "string"},
      uniqueItems: true
    })
  end

  it "supports tuple schemas with prefixItems" do
    schema_class.tuple :coordinates do
      number description: "Latitude"
      number description: "Longitude"
    end

    expect(schema_class.properties[:coordinates]).to eq({
      type: "array",
      prefixItems: [
        {type: "number", description: "Latitude"},
        {type: "number", description: "Longitude"}
      ],
      minItems: 2,
      maxItems: 2
    })
  end

  it "supports tuple schemas with object entries" do
    schema_class.tuple :event do
      string description: "Event name"
      integer description: "Unix timestamp"
      object description: "Payload" do
        string :id
        string :source
      end
    end

    event_schema = schema_class.properties[:event]

    expect(event_schema[:prefixItems].length).to eq(3)
    expect(event_schema[:prefixItems][2][:properties][:id]).to eq({type: "string"})
    expect(event_schema[:minItems]).to eq(3)
    expect(event_schema[:maxItems]).to eq(3)
  end

  it "supports contains with minContains and maxContains" do
    schema_class.array :scores do
      contains min: 1, max: 3 do
        integer minimum: 10
      end
    end

    expect(schema_class.properties[:scores]).to eq({
      type: "array",
      contains: {type: "integer", minimum: 10},
      minContains: 1,
      maxContains: 3
    })
  end

  it "supports contains alongside an item schema" do
    schema_class.array :scores do
      integer

      contains do
        integer minimum: 10
      end
    end

    expect(schema_class.properties[:scores]).to eq({
      type: "array",
      items: {type: "integer"},
      contains: {type: "integer", minimum: 10}
    })
  end

  it "keeps existing homogeneous item behavior" do
    schema_class.array :items, of: :integer

    expect(schema_class.properties[:items]).to eq({
      type: "array",
      items: {type: "integer"}
    })
  end
end
