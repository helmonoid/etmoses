require 'rails_helper'

RSpec.describe MarketModelTemplate do
  it { expect(subject).to validate_presence_of(:name) }

  context "when validating" do
    let(:market) {
      FactoryGirl.build(:market_model_template,
        name: "Test",
        interactions: [interaction])
    }

    let(:interaction) {
      {
        "stakeholder_from"    => "customer",
        "stakeholder_to"      => "producer",
        "tariff"              => 1.0,
        "tariff_type"         => "fixed",
        "applied_stakeholder" => "customer",
        "foundation"          => "abc"
      }
    }

    let(:messages) { market.valid? ; market.errors[:interactions] }

    context "an interaction using merit tariff type and with no tariff" do
      let(:interaction) do
        super().merge('tariff_type' => 'merit', 'tariff' => '')
      end

      it 'is valid' do
        expect(market).to be_valid
      end
    end # an interaction using merit tariff type and with no tariff

    MarketModelTemplate::PRESENTABLES.each do |attribute|
      describe "an interaction with no '#{ attribute }'" do
        let(:interaction) { super().update(Hash[attribute, ""]) }

        let(:translated_attribute) do
          I18n.t("market_model_template.table.headers.#{ attribute }").downcase
        end

        it 'is not valid' do
          expect(market).to_not be_valid
        end

        it 'has an error on :interactions' do
          expect(messages).to include(
            "value for #{ translated_attribute } can't be blank")
        end
      end

      describe "an interaction with a missing '#{ attribute }'" do
        let(:interaction) { super().except(attribute) }

        let(:translated_attribute) do
          I18n.t("market_model_template.table.headers.#{ attribute }").downcase
        end

        it 'is not valid' do
          expect(market).to_not be_valid
        end

        it 'has an error on :interactions' do
          expect(messages).to include(
            "value for #{ translated_attribute } can't be blank")
        end
      end
    end
  end

  context 'with an irregular-length measure' do
    before do
      subject.interactions = [{
        'tariff_type'      => nil,
        'tariff'           => 1.0,
        'foundation'       => 'kw_max',
        'stakeholder_from' => 'one',
        'stakeholder_to'   => 'two'
      }]
    end

    it 'should have an error when using a curve tariff' do
      subject.interactions.first['tariff_type'] = 'curve'

      expect(subject.errors_on(:base)).to include(
        "You may not use a curve tariff with the " \
        "'monthly maximum kW load' measure."
      )
    end

    it 'should have an error when using the merit tariff' do
      subject.interactions.first['tariff_type'] = 'merit'

      expect(subject.errors_on(:base)).to include(
        "You may not use a merit tariff with the " \
        "'monthly maximum kW load' measure."
      )
    end

    it 'should have no error when using a fixed tariff' do
      subject.interactions.first['tariff_type'] = 'fixed'
      expect(subject.errors_on(:base)).to be_blank
    end
  end # with an irregular-length measure

  context 'with a regular-length measure' do
    before do
      subject.interactions = [{
        'tariff_type'      => nil,
        'tariff'           => 1.0,
        'foundation'       => 'load',
        'stakeholder_from' => 'one',
        'stakeholder_to'   => 'two'
      }]
    end

    it 'should have an no errors when using a curve tariff' do
      subject.interactions.first['tariff_type'] = 'curve'
      expect(subject.errors_on(:base)).to be_blank
    end

    it 'should have an error when using the merit tariff' do
      subject.interactions.first['tariff_type'] = 'merit'
      expect(subject.errors_on(:base)).to be_blank
    end

    it 'should have no error when using a fixed tariff' do
      subject.interactions.first['tariff_type'] = 'fixed'
      expect(subject.errors_on(:base)).to be_blank
    end
  end # with a regular-length measure
end
