require 'rails_helper'

RSpec.describe TechnologyList do
  let(:hash) { YAML.load(<<-YML.strip_heredoc) }
    ---
    lv1:
    - name: One
      load: 1.2
    - name: Two
      load: -0.3
    lv2:
    - name: Three
      load: 3.2
    - name: Four
      load: 0.1
  YML

  describe '.load' do
    it 'returns an empty list when given nil' do
      list = TechnologyList.load(nil)

      expect(list).to be_a(TechnologyList)
      expect(list).to be_empty
    end

    it 'returns a TechnologyList with the parsed techs' do
      list = TechnologyList.load(JSON.dump(hash))

      expect(list).to be_a(TechnologyList)

      expect(list['lv1']).to be_a(Array)
      expect(list['lv2']).to be_a(Array)

      expect(list['lv1'].length).to eq(2)
      expect(list['lv2'].length).to eq(2)
    end
  end # .load

  describe '.from_hash' do
    let(:list) { TechnologyList.from_hash(hash) }

    it 'includes the defined nodes' do
      expect(list['lv1']).to be_a(Array)
      expect(list['lv2']).to be_a(Array)
    end

    it 'includes the defined technologies' do
      expect(list['lv1'][0].name).to eq('One')
      expect(list['lv1'][1].name).to eq('Two')

      expect(list['lv2'][0].name).to eq('Three')
      expect(list['lv2'][1].name).to eq('Four')
    end
  end # .from_hash

  describe '.dump' do
    let(:dump) { TechnologyList.dump(TechnologyList.from_hash(hash)) }

    it 'returns a string' do
      expect(dump).to be_a(String)
    end

    it 'is a JSON document when there are some techs' do
      expect(dump).to start_with('{')
      expect(dump).to end_with('}')

      expect(dump.length > 2).to be
    end

    it 'is an empty JSON string when there are no techs' do
      expect(TechnologyList.dump(TechnologyList.new)).to eq('{}')
    end
  end # .dump
end # TechnologyList
