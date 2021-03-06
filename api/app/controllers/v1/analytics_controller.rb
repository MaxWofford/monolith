module V1
  class AnalyticsController < ApplicationController
    SEGMENT_WRITE_KEY = Rails.application.secrets.segment_write_key

    def identify
      segment(:identify, %w(user_id))
    end

    def track
      segment(:track, %w(user_id event properties))
    end

    def page
      segment(:page, %w(user_id name))
    end

    def group
      segment(:group, %w(user_id group_id))
    end

    private

    def segment(method, allowed_arguments)
      analytics = Segment::Analytics.new(write_key: SEGMENT_WRITE_KEY)
      arguments = params.permit(allowed_arguments).to_h

      analytics.public_send(method, arguments)

      render json: { ok: true, method: method, arguments: arguments },
             status: 200
    rescue => e
      render json: { ok: false, error: e.message }
    end
  end
end
