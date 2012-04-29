
require_relative 'spec_helper'
require 'callfuture.me'
require 'rack/test'

describe CallFutureMe::Application do
  Application = CallFutureMe::Application
  Message = CallFutureMe::Message

  include Rack::Test::Methods

  def app
    @app ||= Application.new
  end

  def json_post(url, data=nil)
    if data
      headers = {'rack.input' => StringIO.new(JSON.generate(data))}
      post url, {}, headers
    else
      post url
    end
  end

  def json_response
    JSON.parse(last_response.body)
  end

  before do
    Ohm.flush
  end

  describe '/message.json' do
    def make_request
      json_post '/message.json',
        :session => {
          :id => 'sid',
          :callId => 'cid',
          :from => {
            :id => '111-222-3333'
          }
        }
    end

    it "returns ok" do
      make_request
      last_response.must_be :ok?
    end

    it "stores an initial Message" do
      make_request
      Message.all.size.must_equal 1
      msg = Message.find(:tropo_session_id => 'sid').first
      msg.recipient_phone.must_equal '111-222-3333'
      msg.state.must_equal 1
    end

    it "returns the correct response" do
      make_request
      msg = Message.find(:tropo_session_id => 'sid').first
      json_response.must_equal \
        'tropo' => [
          {
            'say' => [
              {
                'value' => "Welcome to the messaging service for call future dot me.",
              }
            ],
          },
          'on' => {
            'event' => 'continue',
            'next' => "/message/#{msg.id}/time_prompt.json"
          }
        ]
    end
  end

  describe '/message/:mid/time_prompt.json' do
    let(:msg) {
      msg = Message.new(
        :tropo_session_id => 'sid',
        :recipient_phone => '111-222-3333',
        :state => 1
      )
      msg.save!
      msg
    }

    def make_request
      json_post "/message/#{msg.id}/time_prompt.json"
    end

    it "returns ok" do
      make_request
      last_response.must_be :ok?
    end

    it "returns the correct response" do
      make_request
      json_response.must_equal(
        'tropo' => [
          {
            'ask' => {
              'name' => 'time',
              'say' => [
                {
                  'event' => 'nomatch',
                  'value' => "Sorry, I didn't understand you. Try something like tomorrow at five fifty four P M, or ten minutes from now.",
                },
                {
                  'event' => 'incomplete',
                  'value' => "Are you still there? If so, tell me when you'd like to receive your message. For example, tomorrow at five fifty four P M, or, ten minutes from now.",
                },
                {
                  'event' => 'timeout',
                  'value' => "Are you still there? If so, tell me when you'd like to receive your message. For example, tomorrow at five fifty four P M, or, ten minutes from now.",
                },
                {
                  'value' => "To begin, tell me when you'd like to receive your message."
                }
              ],
              'choices' => {
                # 'value' => CallFutureMe::Application.public_url('/time.grxml')
                'value' => '[ANY]',
                'mode' => 'speech'
              },
              'timeout' => 4  # seconds
            },
          },
          {
            'on' => {
              'event' => 'incomplete',
              'next' => "/message/#{msg.id}/time_prompt.json"
            },
          },
          {
            'on' => {
              'event' => 'continue',
              'next' => "/message/#{msg.id}/time.json"
            }
          }
        ]
      )
    end
  end
end
