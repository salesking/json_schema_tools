require 'spec_helper'

describe SchemaTools::Cleaner do

  context 'params cleaning' do
    let(:params){
      { id: 'some id',
        last_name: 'Clean',
        first_name: 'Paul',
        phone_mobile: 110
      }
    }

    after :each do
      SchemaTools::Reader.registry_reset
    end

    it 'should remove invalid keys from hash' do
      SchemaTools::Cleaner.clean_params!(:client, params)
      params[:last_name].should == 'Clean'
      params[:id].should be_nil
    end

    it 'should convert values for string fields' do
      SchemaTools::Cleaner.clean_params!(:client, params)
      params[:phone_mobile].should == '110'
    end
  end
end

