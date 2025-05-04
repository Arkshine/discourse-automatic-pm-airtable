# frozen_string_literal: true

# name: discourse-automatic-pm-airtable
# about: Creates automatically PMs from an Airtable form
# meta_topic_id: TODO
# version: 0.0.1
# authors: Arkshine
# url: TODO
# required_version: 2.7.0

enabled_site_setting :automatic_pm_airtable_enabled

module ::AutomaticPmAirtable
  PLUGIN_NAME = "discourse-automatic-pm-airtable"
end

require_relative "lib/automatic_pm_airtable/engine"

after_initialize do
  require_relative "app/controllers/automatic_pm_airtable/airtable_callback_controller"
end
