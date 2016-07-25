module Market
  class PaymentRule
    # Public: Creates a new payment rule.
    #
    # measure  - A callable which will retrieve the value from the measurable
    #            objects. This should be an object responding to "call" and
    #            which accepts one or two arguments. If the measure returns a
    #            year-round value, it should take one argument. If it needs to
    #            measure a separate value for each hour, the second argument is
    #            the frame to be computed.
    # tariff   - A numeric describing the price.
    # detector - The object which extracted the measurables from the network;
    #            used to supply the variants to the measure.
    #
    # Returns a PaymentRule.
    def initialize(measure, tariff, detector = Detectors::Default.new)
      @measure  = measure
      @detector = detector
      @tariff   = tariff

      @arity =
        if measure.respond_to?(:arity)
          measure.arity
        else
          measure.method(:call).arity
        end
    end

    # Public: Run the payment rule on a given relation.
    def call(relation, variants = {})
      values = Array(value(relation, variants))

      if values.empty?
        # If the measure returns nothing, the "applied to" stakeholder does not
        # exist in the network.
        0.0
      else
        amount = @tariff.price_of(values)
        amount < 0 ? 0.0 : amount
      end
    end

    #######
    private
    #######

    def value(relation, variants)
      values = []

      relation.measurables.sum do |measurable|
        result = if @arity > 1
          @measure.call(measurable, variants_for(measurable, variants))
        else
          @measure.call(measurable)
        end

        Array(result).each_with_index do |value, index|
          values[index] ||= 0.0
          values[index] += value
        end
      end

      values
    end

    def variants_for(measurable, variants)
      @detector.variants_for(measurable, variants)
    end
  end # PaymentRule
end # Market
