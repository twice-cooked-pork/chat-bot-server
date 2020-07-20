require 'google/cloud/firestore'
require 'ibm_watson/authenticators'
require 'ibm_watson/assistant_v2'

class WatsonClient
  def initialize(user_id:)
    authenticator = IBMWatson::Authenticators::IamAuthenticator.new(
      apikey: ENV.fetch('WATSON_API_KEY'),
    )
    firestore = Google::Cloud::Firestore.new project_id: ENV.fetch('GOOGLE_PROJECT_ID')
    @session_doc = firestore.doc("sessions/#{user_id}")

    @service = IBMWatson::AssistantV2.new(
      authenticator: authenticator,
      version: '2018-09-17',
    )
    @service.service_url = ENV.fetch('WATSON_SERVICE_URL')

    @assistant_id = ENV.fetch('WATSON_ASSISTANT_ID')

    store_session_id unless @session_doc.get.fields

    @session_id = @session_doc.get.fields[:session_id]
  end

  def send_message(message)
    message = message.split(/\n/).join(' ')

    begin
      response = @service.message(
        assistant_id: @assistant_id,
        session_id: @session_id,
        input: { 'text' => message },
      )
    rescue IBMCloudSdkCore::ApiException
      store_session_id
      @session_id = @session_doc.get.fields[:session_id]
      retry
    end

    option_item = response.result['output']['generic'].find { |gen| gen['response_type'] == 'option' }
    text_item = response.result['output']['generic'].find { |gen| gen['response_type'] == 'text' }

    result = if option_item
        option_item['options']&.map do |opt|
          [opt['label'].to_sym, opt['value']['input']['text']]
        end
      else
        []
      end
    result.push([:text, text_item['text']]) if text_item

    result.to_h
  end

  def store_session_id
    session_id = @service.create_session(
      assistant_id: @assistant_id,
    ).result['session_id']

    @session_doc.set(session_id: session_id)
  end
end
