# frozen_string_literal: true

require "spec_helper"

RSpec.describe Schematist::Schema, "unevaluated keywords" do
  let(:schema_class) { Class.new(described_class) }

  it "supports unevaluatedProperties on composition schemas" do
    schema_class.all_of :person, unevaluated_properties: false do
      object do
        string :name
      end

      object do
        integer :age
      end
    end

    person_schema = schema_class.properties[:person]

    expect(person_schema[:allOf].length).to eq(2)
    expect(person_schema[:unevaluatedProperties]).to be(false)
  end

  it "leaves an all_of's object branches open so unevaluated_properties can see across them" do
    schema_class.all_of :person, unevaluated_properties: false do
      object do
        string :name
      end

      object do
        integer :age
      end
    end

    branches = schema_class.properties[:person][:allOf]

    expect(branches).to all(satisfy { |branch| !branch.key?(:additionalProperties) })
    expect(branches.map { |branch| branch[:required] }).to eq([[:name], [:age]])
  end

  it "keeps additional_properties set inside an all_of branch" do
    schema_class.all_of :person, unevaluated_properties: false do
      object do
        string :name
        additional_properties false
      end

      object do
        integer :age
      end
    end

    branches = schema_class.properties[:person][:allOf]

    expect(branches.map { |branch| branch[:additionalProperties] }).to eq([false, nil])
  end

  it "keeps object branches closed in an all_of without unevaluated_properties" do
    schema_class.all_of :person do
      object do
        string :name
      end
    end

    expect(schema_class.properties[:person][:allOf].first[:additionalProperties]).to be(false)
  end

  it "keeps object branches closed in a one_of with unevaluated_properties" do
    schema_class.one_of :payment, unevaluated_properties: false do
      object do
        string :card_number
      end
    end

    expect(schema_class.properties[:payment][:oneOf].first[:additionalProperties]).to be(false)
  end

  it "keeps an all_of branch built from a schema class as the class declares it" do
    address = Class.new(described_class) { string :street }

    schema_class.all_of :place, unevaluated_properties: false do
      object of: address

      object do
        address
      end
    end

    branches = schema_class.properties[:place][:allOf]

    expect(branches.map { |branch| branch[:additionalProperties] }).to eq([false, false])
  end

  it "emits open branches under a root all_of that closes them with unevaluated_properties" do
    schema = Schematist::Schema.create do
      all_of unevaluated_properties: false do
        object do
          string :textValue
        end

        object do
          number :numberValue
        end
      end
    end

    expect(schema.new.to_json_schema).to include(
      "allOf" => [
        {"type" => "object", "properties" => {"textValue" => {"type" => "string"}}, "required" => ["textValue"]},
        {"type" => "object", "properties" => {"numberValue" => {"type" => "number"}}, "required" => ["numberValue"]}
      ],
      "unevaluatedProperties" => false
    )
  end

  it "supports unevaluatedProperties on referenced object schemas" do
    schema_class.define :person do
      string :name
    end

    schema_class.object :person, of: :person, unevaluated_properties: false

    expect(schema_class.properties[:person]).to eq({
      "$ref" => "#/$defs/person",
      unevaluatedProperties: false
    })
  end

  it "supports unevaluatedProperties on inline object schemas" do
    schema_class.object :metadata, unevaluated_properties: false do
      string :name
    end

    metadata_schema = schema_class.properties[:metadata]

    expect(metadata_schema[:properties][:name]).to eq({type: "string"})
    expect(metadata_schema[:unevaluatedProperties]).to be(false)
  end

  it "supports unevaluatedItems on array schemas" do
    schema_class.array :values, of: :integer, unevaluated_items: false

    expect(schema_class.properties[:values]).to eq({
      type: "array",
      items: {type: "integer"},
      unevaluatedItems: false
    })
  end
end
