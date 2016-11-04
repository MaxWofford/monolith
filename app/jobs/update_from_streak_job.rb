class UpdateFromStreakJob < ApplicationJob
  queue_as :default

  CLUB_PIPELINE = Rails.application.secrets.streak_club_pipeline_key
  LEADER_PIPELINE = Rails.application.secrets.streak_leader_pipeline_key

  def perform(*)
    club_pipeline = StreakClient::Pipeline.find(CLUB_PIPELINE)
    leader_pipeline = StreakClient::Pipeline.find(LEADER_PIPELINE)

    club_boxes = StreakClient::Box.all_in_pipeline(CLUB_PIPELINE)
    leader_boxes = StreakClient::Box.all_in_pipeline(LEADER_PIPELINE)

    # Create and update clubs
    club_boxes.each do |box|
      field_maps = Club.field_mappings
      club = Club.find_or_initialize_by(streak_key: box[:key])

      club.update_attributes(
        name: box[:name],
        address: box[:fields][field_maps[:address].to_sym],
        latitude: box[:fields][field_maps[:latitude].to_sym],
        longitude: box[:fields][field_maps[:longitude].to_sym],
        source: dropdown_value(
          club_pipeline,
          field_maps[:source][:key],
          box[:fields][field_maps[:source][:key].to_sym]
        ),
        notes: box[:notes]
      )

      # Delete old relationships
      club.leaders.each do |leader|
        unless box[:linked_box_keys].include? leader.streak_key
          club.leaders.delete(leader)
        end
      end
    end

    # Delete clubs that are no longer present
    Club.find_each do |c|
      exists_in_streak = false

      club_boxes.each do |box|
        if c.streak_key == box[:key]
          exists_in_streak = true
        end
      end

      c.destroy_without_streak! unless exists_in_streak
    end

    leader_boxes.each do |box|
      field_maps = Leader.field_mappings

      leader = Leader.find_or_initialize_by(streak_key: box[:key])

      leader.update_attributes(
        name: box[:name],
        gender: dropdown_value(
          leader_pipeline,
          field_maps[:gender][:key],
          box[:fields][field_maps[:gender][:key].to_sym]
        ),
        year: dropdown_value(
          leader_pipeline,
          field_maps[:year][:key],
          box[:fields][field_maps[:year][:key].to_sym]
        ),
        email: box[:fields][field_maps[:email].to_sym],
        phone_number: box[:fields][field_maps[:phone_number].to_sym],
        slack_username: box[:fields][field_maps[:slack_username].to_sym],
        github_username: box[:fields][field_maps[:github_username].to_sym],
        twitter_username: box[:fields][field_maps[:twitter_username].to_sym],
        address: box[:fields][field_maps[:address].to_sym],
        latitude: box[:fields][field_maps[:latitude].to_sym],
        longitude: box[:fields][field_maps[:longitude].to_sym],
        notes: box[:notes]
      )

      box[:linked_box_keys].each do |linked_box_key|
        c = Club.find_by(streak_key: linked_box_key)
        unless c.nil? or c.leaders.include? leader
          c.leaders << leader
        end
      end
    end

    # Delete leaders that are no longer present
    Leader.find_each do |l|
      exists_in_streak = false

      leader_boxes.each do |box|
        if l.streak_key == box[:key]
          exists_in_streak = true
        end
      end

      l.destroy_without_streak! unless exists_in_streak
    end
  end

  private

  def dropdown_value(pipeline, field_key, dropdown_value_key)
    return nil if dropdown_value_key.nil?

    field_spec = pipeline[:fields].find { |f| f[:key] == field_key }
    dropdown_items = field_spec[:dropdown_settings][:items]

    item = dropdown_items.find { |i| i[:key] == dropdown_value_key }

    item[:name]
  end
end
