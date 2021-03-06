module Network
  # Describes a path from a technology on an endpoint to a parent node. This may
  # be the route from the technology to the owner node, or any ancestor node
  # thereof (including the network head node).
  class SubPath < TechnologyPath
    extend Forwardable

    def_delegators :@full_path, :receipts

    # Public: Given a TechnologyPath which describes the path from a technology
    # to the network head, returns an array of all subpaths from the technology
    # to the ancestor nodes.
    #
    # Returns an array of TechnologyPath instances.
    def self.from(full_path)
      path = full_path.to_a

      subpaths = path.length.times.map do |iter|
        new(Path.new(path[0...(iter + 1)]), full_path)
      end

      subpaths
    end

    # Public: The original path from the technology to the graph head.
    attr_reader :full_path

    def initialize(sub_path, full_path)
      super(full_path.technology, sub_path)

      @full_path = full_path

      # The final full-length path should not be limited to excess.
      @full_length = @full_path.length == sub_path.length

      @applied_negative_loads = []
    end

    def mandatory_consumption_at(frame)
      limit_to_excess(frame, super)
    end

    def conditional_consumption_at(frame)
      limit_to_excess(frame, super)
    end

    # Public: Informs the path that an +amount+ of energy is to be consumed.
    #
    # Adds the consumption to the tech load hash, to track the user.
    #
    # Returns nothing.
    def consume(frame, amount, conditional = false)
      @full_path.consume(frame, amount, conditional)

      type = @full_path.technology.installed.type

      @path.each do |node|
        node.tech_loads[type][frame] ||= 0.0
        node.tech_loads[type][frame] += amount
      end

      # Account for the consumption by removing production tech loads.
      subtract_tech_production!(frame, amount) if amount > 0
    end

    # Internal: Describes the length that the path should be in which we
    # apply a negative tech load to each node in the path, to fix the
    # anomalous double-counting of reclaimed storage energy.
    #
    # Returns an integer.
    def negative_storage_tech_load?
      length == 1 && @full_path.technology.try(:emit_retain?)
    end

    def distance
      @full_path.length - length
    end

    def subpath?
      ! @full_length
    end

    private

    # Internal: Returns the nodes between the head of this path and the head of
    # the network.
    #
    # For example
    #
    #   Full path: [A, B, C, D, E]
    #   Sub path:  [A, B]
    #   Inverse:   [C, D, E]
    #
    # Returns a Path
    def inverse
      @inverse ||= Path.new(@full_path.to_a - to_a)
    end

    # Internal: Takes an +amount+ of production away from technologies on this
    # path. Production remains present on all nodes in the sub path, but is
    # removed from parent nodes between the path's head and the head of the
    # network.
    #
    # Returns nothing.
    def subtract_tech_production!(frame, amount)
      inverse.each do |node|
        # Amount of energy to be removed from the +node+'s level in the network.
        level_amount = amount

        node.tech_loads.each do |tech_key, loads|
          next unless loads[frame] < 0

          produced = -loads[frame]
          removed  = produced < level_amount ? produced : level_amount

          node.tech_loads[tech_key][frame] += removed
          level_amount -= removed

          break if level_amount <= 0
        end
      end
    end

    def limit_to_excess(frame, amount)
      return amount if @full_length

      excess = excess_at(frame)
      amount < excess ? amount : excess
    end
  end # SubPath
end
