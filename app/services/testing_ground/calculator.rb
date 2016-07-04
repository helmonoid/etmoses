class TestingGround::Calculator
  include Validator
  include BackgroundJob

  attr_reader :options

  def initialize(testing_ground, options = {})
    @testing_ground = testing_ground
    @options        = options || {}
  end

  def calculate
    if ready?
      destroy_background_job
      base.merge(networks: tree, tech_loads: tech_loads)
    else
      calculate_background_job
      strategies.merge(pending: existing_job.present?)
    end
  end

  def network(carrier)
    fetch_networks.detect { |net| net.carrier == carrier }
  end

  # Public: Returns if the testing ground is ready to return the computes
  # networks.
  #
  # If caching is enabled, this means that a fully-computed network is cached
  # and may be read. If caching is disabled, the calculator is always ready and
  # will force a recalculation.
  #
  # Returns true or false.
  def ready?
    ! Settings.cache.networks ||
      # Temporary workaround for #1028, and the weekly cache's inability to deal
      # with multiple simultaneous requests for different weeks.
      weekly_calculation? ||
      cache.present?
  end

  private

  def weekly_calculation?
    resolution == :high && range
  end

  def base
    { technologies: @testing_ground.technology_profile.as_json,
      error: validation_error }
  end

  def tree
    TestingGround::TreeSampler.sample(networks, resolution, @options[:nodes])
  end

  def tech_loads
    networks.each_with_object({}) do |network, data|
      data[network.carrier] = network.nodes.each_with_object({}) do |node, node_data|
        node_data[node.key] = Hash[(node.get(:tech_loads) || {}).map do |tech, loads|
          [tech, TestingGround::TreeSampler.downsample(loads, resolution)]
        end]
      end
    end
  end

  def networks
    [network(:electricity), network(:gas), network(:heat)]
  end

  def fetch_networks
    @networks ||=
      if Settings.cache.networks && ! weekly_calculation?
        cache.fetch(@options[:nodes])
      else
        @testing_ground.to_calculated_graphs(calculation_options)
      end
  end

  def calculation_options
    { strategies: strategies, range: range, resolution: resolution }
  end

  def cache
    @cache ||= NetworkCache::Cache.new(@testing_ground, calculation_options)
  end

  def strategies
    @options[:strategies] || {}
  end

  def resolution
    (@options[:resolution] || 'high').to_sym
  end

  def range
    if @options[:range_start] && @options[:range_end]
      (@options[:range_start].to_i..@options[:range_end].to_i)
    end
  end
end
