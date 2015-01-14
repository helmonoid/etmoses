require 'spec_helper'
require 'yaml'

RSpec.describe 'Building a graph' do
  context 'with String keys' do
    let(:structure) { [{ 'name' => 'HV Network' }] }
    let(:graph)     { ETLoader.build(structure) }

    it 'creates the graph correctly' do
      expect(graph.node('HV Network')).to be
    end
  end # with String keys

  context 'with Symbol keys' do
    let(:structure) { [{ name: 'HV Network' }] }
    let(:graph)     { ETLoader.build(structure) }

    it 'creates the graph correctly' do
      expect(graph.node('HV Network')).to be
    end
  end # with Symbol keys

  context 'with a simple HV/MV/LVx3 layout' do
    let(:structure) do
      YAML.load(<<-EOS.gsub(/ {6}/, ''))
      ---
      - name: HV Network
        children:
        - name: MV Network
          children:
          - name: "LV #1"
          - name: "LV #2"
          - name: "LV #3"
      EOS
    end

    let(:graph) { ETLoader.build(structure) }

    it 'returns a Turbine::Graph' do
      expect(graph).to be_a(Turbine::Graph)
    end

    context 'HV Network' do
      let(:node) { graph.node('HV Network') }

      it 'exists' do
        expect(node).to be
      end

      it 'has no parents' do
        expect(node.in.to_a).to be_empty
      end
    end # HV Network

    context 'MV Network' do
      let(:node) { graph.node('MV Network') }

      it 'exists' do
        expect(node).to be
      end

      it 'belongs to "HV Network"' do
        expect(node.in.first).to eq(graph.node('HV Network'))
      end

      it 'has three children' do
        expect(node.out.to_a.length).to eq(3)
      end
    end # MV Network

    [ 'LV #1', 'LV #2', 'LV #3' ].each do |lv|
      context lv do
        let(:node) { graph.node(lv) }

        it 'exists' do
          expect(node).to be
        end

        it 'belongs to "MV Network"' do
          expect(node.in.first).to eq(graph.node('MV Network'))
        end

        it 'has no children' do
          expect(node.out.to_a).to be_empty
        end

        it 'has no technologies' do
          expect(node.get(:technologies)).to be_empty
        end
      end
    end # LV #1, LV #2, LV #3
  end # with a simple HV/MV/LVx3 layout

  context 'with a node which has custom properties' do
    let(:structure) do
      [{ name: 'Leaf', children: [] }]
    end

    let(:graph) { ETLoader.build([{ name: 'Leaf', capacity: 2.0 }]) }
    let(:node)  { graph.node('Leaf') }

    it 'sets the property on the node' do
      expect(node.get(:capacity)).to eq(2.0)
    end

    it 'does not set a :name property' do
      expect(node.properties.keys).to_not include(:name)
    end

    it 'does not set a :children property' do
      expect(node.properties.keys).to_not include(:children)
    end
  end # with a node which has custom properties

  context 'with a node with Heat Pump and Solar technologies' do
    let(:structure) do
      [{ name: 'Leaf' }]
    end

    let(:technologies) do
      YAML.load(<<-EOS.gsub(/ {6}/, ''))
      ---
      Leaf:
      - name: Heat Pump
        efficiency: 4.0
        capacity: 2.5
      - name: Solar Panel
        efficiency: 1.0
        capacity: 1.5
      EOS
    end

    let(:graph) { ETLoader.build(structure, technologies) }
    let(:node)  { graph.node('Leaf') }

    it 'includes a Heat Pump' do
      expect(node.get(:technologies)).to have_key('Heat Pump')
    end

    it 'sets the Heat Pump attributes' do
      tech = node.get(:technologies)['Heat Pump']

      expect(tech.to_h).to eq(
        name: 'Heat Pump', efficiency: 4.0, capacity: 2.5)
    end

    it 'includes a Solar Panel' do
      expect(node.get(:technologies)).to have_key('Solar Panel')
    end

    it 'sets the Solar Panel attributes' do
      tech = node.get(:technologies)['Solar Panel']

      expect(tech.to_h).to eq(
        name: 'Solar Panel', efficiency: 1.0, capacity: 1.5)
    end
  end # a node with some attached technologies
end # Building a graph
