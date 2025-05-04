# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module ::AutomaticPmAirtable
  BOT_USERNAME = SiteSetting.automatic_pm_airtable_sender

  class AirtableCallbackController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    skip_before_action :verify_authenticity_token, only: [:webhook]

    def webhook
      payload = request.raw_post
      Rails.logger.info("Airtable webhook received: #{payload}")

      begin
        data = JSON.parse(payload)
        record = data["record"]

        if record && record["fields"]
          usernames = record["fields"]["usernames"]
          message_title = record["fields"]["title"]
          message_content = record["fields"]["content"]

          result = create_private_message(BOT_USERNAME, usernames, message_title, message_content)

          if result[:success]
            render json: {
                     success: true,
                     topic_id: result[:topic].id,
                     message: "Successfully created PM between #{usernames.join(", ")}",
                   }
          else
            render json: { success: false, error: result[:message] }, status: 422
          end
        else
          render json: {
                   success: false,
                   error: "Required fields not found in webhook payload",
                 },
                 status: 400
        end
      rescue JSON::ParserError => e
        Rails.logger.error("Error parsing webhook payload: #{e.message}")
        render json: { success: false, error: "Invalid JSON payload" }, status: 400
      rescue => e
        Rails.logger.error("Error processing webhook: #{e.message}")
        render json: { success: false, error: e.message }, status: 500
      end
    end

    private

    def create_private_message(sender_username, recipient_usernames, title, raw_content)
      sender = User.find_by(username: sender_username)
      return { success: false, message: "Sender bot not found" } unless sender

      valid_usernames = []
      recipient_usernames.each do |username|
        user = User.find_by(username: username)
        valid_usernames << username if user
      end

      return { success: false, message: "No valid recipients found" } if valid_usernames.empty?

      creator =
        PostCreator.new(
          sender,
          title: title,
          raw: raw_content,
          archetype: Archetype.private_message,
          target_usernames: valid_usernames.join(","),
          skip_validations: true,
        )

      post = creator.create

      if creator.errors.present?
        { success: false, message: creator.errors.full_messages.join(", ") }
      else
        { success: true, post: post, topic: post.topic }
      end
    rescue => e
      { success: false, message: "Error creating private message: #{e.message}" }
    end
  end
end
