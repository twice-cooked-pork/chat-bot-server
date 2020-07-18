require 'google/cloud/firestore'
require 'ibm_watson/authenticators'
require 'ibm_watson/assistant_v2'
Dotenv.load

class WatsonClient
  def initialize(user_id:)
    authenticator = IBMWatson::Authenticators::IamAuthenticator.new(
      apikey: ENV.fetch('WATSON_API_KEY')
    )

    @service = IBMWatson::AssistantV2.new(
      authenticator: authenticator,
      version: '2018-09-17'
    )
    @service.service_url = ENV.fetch('WATSON_SERVICE_URL')

    @assistant_id = ENV.fetch('WATSON_ASSISTANT_ID')

    firestore = Google::Cloud::Firestore.new project_id: ENV.fetch('GOOGLE_PROJECT_ID')
    doc = firestore.doc("sessions/#{user_id}")

    unless doc.get.fields
      session_id = @service.create_session(
        assistant_id: @assistant_id
      ).result['session_id']
      p session_id
      doc.set(session_id: session_id)
    end

    @session_id = doc.get.fields[:session_id]
  end

  def send_message(message)
    response = @service.message(
      assistant_id: @assistant_id,
      session_id: @session_id,
      input: { 'text' => message }
    )

    option_item = response.result['output']['generic'].find { |gen| gen['response_type'] == 'option' }
    result = option_item['options']&.map do |opt|
      [opt['label'].to_sym, opt['value']['input']['text']]
    end

    result.to_h
  end
end
