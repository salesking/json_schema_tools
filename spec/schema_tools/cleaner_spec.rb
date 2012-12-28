require 'spec_helper'

describe SchemaTools::Cleaner do

  context 'params cleaning' do
    let(:params){
      { id: 'some id',
        last_name: 'Clean',
        first_name: 'Paul'
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
  end
end

