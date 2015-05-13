class InstalledTechnology
  include Virtus.model

  attribute :name,     String
  attribute :type,     String, default: 'generic'
  attribute :behavior, String
  attribute :profile,  String
  attribute :load,     Float
  attribute :capacity, Float
  attribute :demand,   Float
  attribute :storage,  Float
  attribute :units,    Float,  default: 1.0

  EDITABLES = %i(name type profile capacity storage units)

  # Public: Returns a template for a technology. For evaluation purposes
  def self.template
    Hash[ self.attribute_set.map do |attr|
      [attr.name.to_s, attr.default_value.call]
    end ]
  end

  # Public: Returns if the technology has been defined in the data/technologies
  # directory.
  #
  # "Freeform" (no "type") technologies will return true.
  #
  # Returns true or false.
  def exists?
    type.blank? || type == 'generic'.freeze || Technology.exists?(key: type)
  end

  # Public: Returns the associated technology (as defined in data/technologies).
  # Techs with no "type" will return the "generic" library tech.
  #
  # Returns a Technology, or raises ActiveRecord::RecordNotFound if the tech
  # does not exist.
  def technology
    type.present? ? Technology.by_key(type) : Technology.generic
  end

  # Public: Returns the load profile Curve, if the :profile attribute is set.
  #
  # Returns a Merit::Curve.
  def profile_curve
    unscaled_profile_curve *
      ((capacity || load || demand || storage || 1.0) * units)
  end

  #######
  private
  #######

  # Internal: Retrieves the Merit::Curve used by the technology, without any
  # scaling applied for demand or capacity.
  #
  # Returns a Merit::Curve.
  def unscaled_profile_curve
    if profile.is_a?(Array)
      Merit::Curve.new(profile)
    elsif capacity || load
      LoadProfile.by_key(profile).merit_curve(:capacity_scaled)
    elsif demand
      LoadProfile.by_key(profile).merit_curve(:demand_scaled)
    else
      LoadProfile.by_key(profile).merit_curve
    end
  end
end # end
