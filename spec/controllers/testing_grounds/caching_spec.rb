require 'rails_helper'

RSpec.describe TestingGroundsController do
  let(:user){ FactoryGirl.create(:user) }

  let!(:sign_in_user) { sign_in(:user, user) }

  let(:topology_graph){ FakeLoadManagement.caching_graph }

  let(:topology){ FactoryGirl.create(:topology, graph: topology_graph) }

  let(:testing_ground){
    FactoryGirl.create(:testing_ground, technology_profile: technology_profile,
                                        topology: topology)
  }

  let(:technology_profile){
    { "CONGESTED_END_POINT_0" => [{
        "name"        => "Solar PV",
        "type"        => "households_solar_pv_solar_radiation",
        "behavior"    => nil,
        "load"        => nil,
        "capacity"    => -1.5,
        "demand"      => nil,
        "volume"      => nil,
        "units"       => 1,
        "concurrency" => "max"
      }]
    }
  }

  describe 'caching' do
    it 'caches the data request' do
      get :data, id: testing_ground

      expect(NetworkCache::Fetcher.from(testing_ground)
              .fetch.node('CONGESTED_END_POINT_0').get(:load).length).to eq(8760)
    end

    it 'caches the data request for strategies separately' do
      get :data, id: testing_ground,
                 strategies: FakeLoadManagement.strategies(saving_base_load: true)

      expect(NetworkCache::Fetcher.from(testing_ground, { saving_base_load: true })
              .fetch.node('CONGESTED_END_POINT_0').get(:load).length
            ).to eq(8760)
    end

    it 'fetches the data instead of calculating' do
      NetworkCache::Writer.from(testing_ground).write

      get :data, id: testing_ground

      expect(NetworkCache::Fetcher.from(testing_ground)
              .fetch.node('CONGESTED_END_POINT_0').get(:load).length).to eq(8760)
    end

    it 'clears the data cache' do
      NetworkCache::Writer.from(testing_ground).write

      get :data, id: testing_ground, clear_cache: true

      expect(NetworkCache::Fetcher.from(testing_ground)
              .fetch.node('CONGESTED_END_POINT_0').get(:load).length).to eq(8760)
    end
  end
end
