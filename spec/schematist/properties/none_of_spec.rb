# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "not properties" do
  let(:schema_class) { Class.new(described_class) }

  it "supports none_of with a single schema" do
    schema_class.none_of :status do
      string enum: ["forbidden"]
    end

    properties = schema_class.properties

    expect(properties[:status]).to eq({
      not: {type: "string", enum: ["forbidden"]}
    })
  end

  it "wraps multiple none_of schemas in anyOf" do
    schema_class.none_of :status do
      string enum: ["forbidden"]
      integer
    end

    properties = schema_class.properties

    expect(properties[:status]).to eq({
      not: {
        anyOf: [
          {type: "string", enum: ["forbidden"]},
          {type: "integer"}
        ]
      }
    })
  end

  it "supports arrays of not schemas" do
    schema_class.array :items do
      none_of :value do
        null
      end
    end

    item_schema = schema_class.properties[:items][:items]

    expect(item_schema).to eq({not: {type: "null"}})
  end
end
