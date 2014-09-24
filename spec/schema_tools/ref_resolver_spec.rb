require 'spec_helper'

describe SchemaTools::RefResolver do
  context 'class methods' do
    it 'should handle simple json pointer' do
      obj = { "bla" => {
        "blub" => :success
      }}

      pointer = "bla/blub"
      found = SchemaTools::RefResolver._retrieve_pointer_from_object pointer, obj
      # not sure what I am doing wrong here, but:
      #    found.should eq :success
      # does not work because
      #    undefined method `eq'
      found.should eq :success

      found = SchemaTools::RefResolver._retrieve_pointer_from_object "non/existant/path", obj
      found.should  be_nil
    end

    it 'should handle json pointer arrays' do
      obj = { "bla" => {
        "blub" => :success,
        "bling" => [3,2,1]
      }}
      pointer = "bla/bling/2"
      found = SchemaTools::RefResolver._retrieve_pointer_from_object pointer, obj
      found.should eq 1

      pointer = "bla/bling/3"
      found = SchemaTools::RefResolver._retrieve_pointer_from_object pointer, obj
      found.should be_nil

    end

    it 'should handle embedded json pointer arrays' do
      obj = { "bla" => {
        "blub" => :success,
        "bling" => [
          {"num" => 3},
          {"num" => 2},
          {"num" => 1}
        ]
      }}
      pointer = "bla/bling/1/num"
      found = SchemaTools::RefResolver._retrieve_pointer_from_object pointer, obj
      found.should eq 2
    end
  end

  it 'should throw an exception on an invalid path' do
    obj = {}
    expect {
      SchemaTools::RefResolver.load_json_pointer("bla")
    }.to raise_error
  end

  it 'should reject absolute URI part' do
    obj = {}
    expect {
      SchemaTools::RefResolver.load_json_pointer("http://www.example.com/#some/stuff")
    }.to raise_error
  end

  it 'should load local ref' do
    pointer = "./basic_definitions.json#definitions"
    obj = SchemaTools::RefResolver.load_json_pointer(pointer)
    obj.length.should eq 3
  end
end
