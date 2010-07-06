class Preference < ActiveRecord::Base

  ##########################
  #    Configuration       #
  ##########################

  default_scope :order => 'name ASC'
  cattr_accessor :config
  @@config ||= {:allowed_value_classes => [String, Numeric, TrueClass, FalseClass, NilClass]}

  # Allow configuration of the classes allowed for preference values in an initializer
  def self.configure(&block)
    yield @@config
  end
  serialize :value

  # No need to allocate new memory for this error string, when it never changes
  SERIALIZATION_CLASS_ERROR_MSG = "[ActiveRecord::SerializationTypeMismatch] class is invalid, configure with Preference.configure."

  ##########################
  #    Named Scopes        #
  ##########################

  # When displaying a list of preferences that are modifiable, we may only want those which
  #   super-admins have made available
  named_scope :available, :conditions => ["available IS TRUE"]
  named_scope :unavailable, :conditions => ["available IS NOT TRUE"]
  named_scope :names, :select => 'name'

  ##########################
  #    Validations         #
  ##########################

  validates_presence_of :name
  validates_uniqueness_of :name
  validate :valid_value_class

  def valid_value_class
    self.errors.add(:value, SERIALIZATION_CLASS_ERROR_MSG) if self.config[:allowed_value_classes].select {|klass| self.value.is_a?(klass)}.empty?
  end

  ##########################
  #    Instance Methods    #
  ##########################

  # testing = true
  #   to override the disabling of a feature via the available boolean column
  #   when testing a new preference in a RBAC/ACL restricted area of the app
  #   where a new feature can be tested prior to being turned on for regular site users.
  def get_value(testing = false)
    self.is_enabled?(testing) ? self.value : nil
  end

  # Ensure that a preference is ready to be accessed based on begin_at and end_at timestamps.
  #   This gives a site admin the ability to modify settings while they sleep by setting a
  #   specific time in the future for the switch to be flipped. End at specifies when it will automatically shut off.
  def is_enabled?(testing = false)
    return false unless self.enabled? && (self.available || testing)
    valid_start_time = self.begin_at.nil? ? true : self.begin_at <= Time.zone.now
    return false unless valid_start_time
    valid_end_time = self.end_at.nil? ? true : self.end_at >= Time.zone.now
    return valid_end_time
  end

  def turn_on_at(time = Time.now, finish = nil)
    self.begin_at = time
    self.end_at = finish
    self.enabled = true
    # We don't touch self.available, as that belongs to RBAC control
    self.save
  end

  def turn_off_at(time = Time.now)
    self.end_at = time
    self.enabled = true
    # We don't touch self.available, as that belongs to RBAC control
    self.save
  end

  ##########################
  #    Class Methods       #
  ##########################

  def self.find_or_create(name, enabled = false, available = false, value = nil, description = nil)
    self.get_pref(name) || self.create({:name => name,
                                              :enabled => enabled,
                                              :available => available,
                                              :value => value,
                                              :description => description})
  end

  def self.all_names
    Rails.cache.fetch("preference:all_names") do
      self.names.map {|x| x.name }
    end
  end

  # Loading a set of preferences they are cached,
  #  as this is how they will be loaded to control things in the UI, or functioning of the app.
  def self.get_prefs(names)
    Rails.cache.fetch("preference:get_prefs:#{names.join('_').parameterize}") do
      self.all(:conditions => ["name IN (?)", names])
    end
  end

  # Loading a preference individually, they are not cached,
  #  because when loaded this way it is to modify the preference in some way, and when loaded from cache they are frozen
  def self.get_pref(name)
    self.find_by_name(name)
  end

  # Standard way to access preference values.
  # If the preference is not enabled, available, or active at this time, returns nil.
  def self.value(name, *args)
    self.try_pref(name, 'get_value', *args)
  end

  def self.turn_on_at(name, *args)
    self.try_pref(name, 'turn_on_at', *args)
  end

  def self.turn_off_at(name, *args)
    self.try_pref(name, 'turn_off_at', *args)
  end

  def self.enabled?(name, *args)
    self.try_pref(name, 'is_enabled?', *args)
  end

  protected
    # protect against missing records and missing methods, so a bad preference call should return false, or nil
    def self.try_pref(name, method, *args)
      (result = self.get_pref( name )) && result.respond_to?(method) && result.send(method, *args)
    end

end

# == Schema Information
#
# Table name: preferences
#
#  id          :integer         not null, primary key
#  name        :string(255)     not null
#  value       :text
#  description :string(255)
#  begin_at    :datetime
#  end_at      :datetime
#  enabled     :boolean         default(FALSE), not null
#  available   :boolean         default(FALSE), not null
#  updated_by  :integer
#  created_at  :datetime
#  updated_at  :datetime
#

