# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "allOf properties" do
  let(:schema_class) { Class.new(described_class) }

  it "supports all_of with mixed schemas" do
    schema_class.all_of :payload do
      object do
        string :name
      end

      object do
        integer :age
      end
    end

    all_of_schemas = schema_class.properties[:payload][:allOf]

    expect(all_of_schemas.length).to eq(2)
    expect(all_of_schemas[0][:properties][:name]).to eq({type: "string"})
    expect(all_of_schemas[1][:properties][:age]).to eq({type: "integer"})
  end

  it "supports arrays of allOf types" do
    schema_class.array :items do
      all_of :value do
        object do
          string :name
        end

        object do
          integer :age
        end
      end
    end

    all_of_schemas = schema_class.properties[:items][:items][:allOf]

    expect(all_of_schemas.length).to eq(2)
    expect(all_of_schemas.map { |schema| schema[:type] }).to eq(%w[object object])
  end
end
