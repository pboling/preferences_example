require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase
  test "Should not save preference without name" do
    p = Preference.new
    assert !p.save
    assert_equal p.errors["name"], "can't be blank"
  end

  test "Should save preference with name" do
    p = Preference.new({:name => 'test1'})
    assert p.save
  end

  test "Should not save preference with duplicate name" do
    p1 = Preference.create({:name => 'duplicate'})
    assert p1.save
    p2 = Preference.new({:name => 'duplicate'})
    p2.save
    assert_equal p2.errors["name"], "has already been taken"
  end

  test "Should be enabled when no begin or end date, and enabled and available are true" do
    p1 = preferences(:site_name)
    assert p1.is_enabled?
  end

  test "Should not be enabled when available is false" do
    p1 = preferences(:max_file_size)
    assert !p1.is_enabled?
  end

  test "Should not be enabled when available is false, and within begin/end dates" do
    p1 = preferences(:min_hat_size)
    assert !p1.is_enabled?
  end

  test "Should not be enabled when enabled is false" do
    p1 = preferences(:max_chipmunk_size)
    assert !p1.is_enabled?
  end

  test "Should not be enabled when enabled is false, and within begin/end dates" do
    p1 = preferences(:min_wallet_size)
    assert !p1.is_enabled?
  end

  test "Should be enabled when current time is between begin date and end date" do
    p1 = preferences(:max_photo_size)
    assert p1.is_enabled?
  end

  test "Should be enabled when current time is after begin date and no end date" do
    p1 = preferences(:cheese_shape)
    assert p1.is_enabled?
  end

  test "Should be enabled when current time is before end date and no begin date" do
    p1 = preferences(:pie_shape)
    assert p1.is_enabled?
  end

  test "Should not be enabled when current time is before begin date" do
    p1 = preferences(:max_antler_size)
    assert !p1.is_enabled?
  end

  test "Should not be enabled when current time is after end date" do
    p1 = preferences(:min_shoe_size)
    assert !p1.is_enabled?
  end

  test "String, Integer, Float, Boolean are only valid value classes" do
    p_string = Preference.create({:name => 'test_string', :value => 'string'})
    assert p_string.save
    p_integer = Preference.create({:name => 'test_integer', :value => 12345})
    assert p_integer.save
    p_float = Preference.create({:name => 'test_float', :value => 9.8765})
    assert p_float.save
    p_true = Preference.create({:name => 'test_true', :value => true})
    assert p_true.save
    p_false = Preference.create({:name => 'test_false', :value => false})
    assert p_false.save
  end

  test "Value can be nil" do
    p_nil = Preference.create({:name => 'test_nil', :value => nil})
    assert p_nil.save
  end

  test "Value cannot be a Hash" do
    p_hash = Preference.create({:name => 'test_hash', :value => {}})
    assert !p_hash.save
  end

  test "Preference.configure should be able to set array of allowed value classes" do
    Preference.configure do |config|
      config[:allowed_value_classes] = [Hash]
    end
    p_hash = Preference.create({:name => 'test_configure', :value => {}})
    assert p_hash.save
    Preference.configure do |config|
      config[:allowed_value_classes] = [String, Numeric, TrueClass, FalseClass, NilClass]
    end
    p_hash = Preference.create({:name => 'test_configure2', :value => {}})
    assert !p_hash.save
  end

  test "get_value should return value if preference is enabled, available, and active right now" do
    p1 = preferences(:site_name)
    assert_equal p1.get_value, "Best Ever Website"
  end

  test "get_value should be able to return value with class String" do
    p1 = preferences(:site_name)
    assert_kind_of(String, p1.get_value)
  end

  #There appears to be a problem marshalling the non-string YAML data to serialized value in DB, as 5 comes out "5".
  test "get_value should be able to return value with class Numeric" do
    p1 = preferences(:max_photo_size)
    p1.value = 5
    p1.save
    p1 = preferences(:max_photo_size)
    assert_kind_of(Numeric, p1.get_value)
  end

  #There appears to be a problem marshalling the non-string YAML data to serialized value in DB, as nil comes out "nil".
  test "get_value should be able to return value true or false" do
    p1 = preferences(:users_can_login)
    p1.value = nil
    p1.save
    assert_kind_of(NilClass, p1.get_value)
    p1.value = false
    p1.save
    assert_kind_of(FalseClass, p1.get_value)
    p1.value = true
    p1.save
    assert_kind_of(TrueClass, p1.get_value)
  end

  test "Should be enabled after turn_on_at when current time is initially after end date" do
    p1 = preferences(:min_shoe_size)
    #starts out disabled due to end_at
    assert !p1.is_enabled?
    p1.turn_on_at(Time.now)
    p2 = preferences(:min_shoe_size)
    #now it is enabled
    assert p2.is_enabled?
  end

  test "Should be disabled after turn_off_at when current time is initially after begin date" do
    p1 = preferences(:cheese_shape)
    #starts out enabled due to begin_at
    assert p1.is_enabled?
    p1.turn_off_at(Time.now)
    p2 = preferences(:cheese_shape)
    #now it is enabled
    assert !p2.is_enabled?
  end

  test "Preference.all_names should return array of preference names" do
    all = Preference.all_names
    assert_kind_of(Array, all)
    #we have a lot of fixtures
    assert all.length > 10
  end

  test "default scope should order alphabetically" do
    all = Preference.all_names
    assert_equal all[0], "Antler Size Maximum"
    assert_equal all[-1], "Zebra Color"
  end

  test "Preference.get_prefs should return an array of preferences" do
    prefs = Preference.get_prefs(['Antler Size Maximum', 'Preferred shape of cheese', 'Max Chipmunk Size', 'This one does not exist'])
    assert_equal prefs.length, 3
    #Should be ordered alphabetically
    assert_equal prefs[-1].name, "Preferred shape of cheese"
  end

  test "Preference.get_pref should return a preference by name" do
    prefs = Preference.get_pref('Max Chipmunk Size')
    assert_equal prefs.name, 'Max Chipmunk Size'
    prefs = Preference.get_pref('I am not here')
    assert_nil prefs
  end

  test "Preference.value should return a preference's value by name" do
    #Max Chipmunk Size is not enabled, so should return nil
    value1 = Preference.value('Max Chipmunk Size')
    assert_nil value1
    #Max Photo Size should give us a value
    value2 = Preference.value('Max Photo Size')
    #Really it should be Fixnum 5, but the serialization insn't working from YAML. :(
    assert_equal value2, "5"
  end

  test "Preference.turn_on_at should turn on a pref by name" do
    #Max Chipmunk Size is not enabled
    assert !Preference.enabled?('Max Chipmunk Size')
    Preference.turn_on_at('Max Chipmunk Size')
    assert Preference.enabled?('Max Chipmunk Size')
    #Antler Size Maximum hasn't begun yet
    assert !Preference.enabled?('Antler Size Maximum')
    Preference.turn_on_at('Antler Size Maximum')
    assert Preference.enabled?('Antler Size Maximum')
  end

  test "Preference.turn_off_at should turn off a pref by name" do
    #Max Photo Size is enabled.
    assert Preference.enabled?('Max Photo Size')
    Preference.turn_off_at('Max Photo Size', Time.zone.now.yesterday)
    assert !Preference.enabled?('Max Photo Size')
  end

  test "Preference.enabled? should tell us if a pref is enabled by name" do
    #Max Chipmunk Size is not enabled, so should return false
    assert !Preference.enabled?('Max Chipmunk Size')
    #Antler Size Maximum hasn't begun yet
    assert !Preference.enabled?('Antler Size Maximum')
    #Max Photo Size is enabled.
    assert Preference.enabled?('Max Photo Size')
  end

  test "Preference.find_or_create should find or create" do
    #Max Photo Size exists:
    mps = Preference.find_or_create('Max Photo Size')
    assert_equal(mps, preferences(:max_photo_size))
    #Num Camel Humps does not exist
    c_humps = Preference.find_or_create('Num Camel Humps', true, true, 3, "How many humps does our camel have?")
    assert c_humps.is_enabled?
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

