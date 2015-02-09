require 'spree_core'
require 'spree/auth/devise'
require 'spree/authentication_helpers'
require 'sass/rails'
require 'coffee_script'
require 'devise_sms_sender'

Spree::PermittedAttributes.user_attributes << :phone
