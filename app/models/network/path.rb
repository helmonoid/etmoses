module Network
  # Describes a path of nodes from a technology node, back to the root.
  class Path
    extend Forwardable
    include Enumerable

    def_delegators :@path, :each, :length

    attr_reader :head, :leaf

    # Public: Given a leaf node, returns a Path which represents the route
    # back to the root node.
    #
    # Returns a Path.
    def self.find(leaf)
      new([leaf, *leaf.ancestors.to_a])
    end

    # Internal: Creates a new Path, using the given array of nodes to describe
    # the path through the parents to the root node.
    def initialize(nodes)
      @path = nodes
      @leaf = nodes.first
      @head = nodes.last
    end

    # Public: The path as an array, with the leaf node first, with each node
    # leading to the root.
    def to_a
      @path.to_a
    end

    def inspect
      "#<#{ self.class.name } #{ self }>"
    end

    def to_s
      "{#{ @path.map(&:key).join(', ') }}"
    end

    # Public: The top-most node in the path.
    def head
      @path.last
    end

    # Public: The conditional consumption being created by the consumption node.
    #
    # Returns a numeric.
    def conditional_consumption_at(frame)
      @leaf.conditional_consumption_at(frame)
    end

    # Public: The mandatory consumption being created by the consumption node.
    #
    # Returns a numeric.
    def mandatory_consumption_at(frame)
      @leaf.mandatory_consumption_at(frame)
    end

    # Public: Returns the minimum available capacity of the nodes in the path.
    # If capacity has been exceeded, 0.0 will be returned, while no set capacity
    # will return Infinity.
    #
    # Returns a numeric.
    def available_capacity_at(frame)
      @path.map { |node| node.available_capacity_at(frame) }.min
    end

    # Public: Determines if the load of the any node in the path node exceeds
    # its capacity.
    #
    # Returns true or false.
    def congested_at?(frame, correction = 0)
      @path.any? { |node| node.congested_at?(frame, correction) }
    end

    def surplus_at(frame)
      @head.production_at(frame) - @head.consumption_at(frame)
    end
  end # Path
end # Network
