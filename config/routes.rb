# frozen_string_literal: true

AutomaticPmAirtable::Engine.routes.draw do
  post "/webhook" => "airtable_callback#webhook"
end

Discourse::Application.routes.draw { mount ::AutomaticPmAirtable::Engine, at: "/airtable" }
