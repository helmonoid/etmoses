class Export
  class NationalScenarioCreator
    # Exporting is a two-step procedure in which we create a new national-scale
    # scenario based on the original, then send the input values with a second
    # request.
    def initialize(testing_ground, exported_technologies)
      @testing_ground        = testing_ground
      @exported_technologies = exported_technologies
    end

    def create
      @new_scenario ||= new_scenario

      EtEngineConnector.new(update_scenario_params)
        .update_scenario(@new_scenario['id'])

      @new_scenario
    end

    private

    def new_scenario
      EtEngineConnector.new(scenario_params).create_scenario
    end

    def scenario_params
      { scenario: {
          scenario_id: @testing_ground.scenario_id,
          descale: true
        }
      }
    end

    def user_values
      Hash[@exported_technologies.map do |technology|
        [technology.export_to, technology.slider_setting]
      end]
    end

    def update_scenario_params
      { autobalance: true,
        force_balance: true,
        scenario: {
          title: @testing_ground.name,
          user_values: user_values
        }
      }
    end
  end
end
