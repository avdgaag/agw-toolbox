require 'agw/toolbox/core_extensions'

ActionController::Base.helper AGW::Toolbox::Helpers
ActionController::Base.helper AGW::Toolbox::PlaceholderHelper

AGW::Toolbox::ListedFormBuilder.setup
AGW::Toolbox::Dutch.setup

ActiveRecord::Base.send   :include, AGW::Toolbox::Validations
Test::Unit::TestCase.send :include, AGW::Toolbox::CustomMatchers
Test::Unit::TestCase.send :include, AGW::Toolbox::ValidationMatchers