
module CallFutureMe
  class Message < Ohm::Model
    include Logging

    include Ohm::Timestamps
    include Ohm::DataTypes

    attribute :tropo_session_id
    attribute :recipient_phone
    # state is:
    # 1) call created
    # 2) time received
    attribute :state, Type::Integer

    attribute :sr_confidence
    attribute :sr_interpretation
    attribute :sr_utterance
    attribute :sr_value
    # attribute :sent_at, Time

    unique :tropo_session_id
    index :tropo_session_id

    def validate
      if state >= 1
        assert_present :tropo_session_id
        assert_present :recipient_phone
        assert_present :state
      end
      if state >= 2
        assert_present :sr_confidence
        assert_present :sr_interpretation
        assert_present :sr_utterance
        assert_present :sr_value
      end
    end
  end
end
