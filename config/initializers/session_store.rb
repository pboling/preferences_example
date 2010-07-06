# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_preference_session',
  :secret      => '80cd5472dd8cc39ed420552ab0e41022898569a4843ecb99ca89034343d13b0a6148c24e966ea31b44c478b1b63fda35826558cb2fcbd1d7baca285b0ab69ab4'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
