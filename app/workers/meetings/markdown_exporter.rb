# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Meetings
  class MarkdownExporter < ::Exports::Exporter
    attr_reader :meeting, :current_user, :participants, :outcomes

    def initialize(meeting, current_user:, participants: true, outcomes: true)
      @meeting = meeting
      @current_user = current_user
      @participants = participants
      @outcomes = outcomes
    end

    def self.key
      :markdown
    end

    def export!
      ::Exports::Result.new(
        format: :markdown,
        mime_type: "text/markdown",
        title: "#{meeting.title}.md",
        content: generate_markdown
      )
    end

    private

    def with_outcomes?
      ActiveModel::Type::Boolean.new.cast(outcomes)
    end

    def with_participants?
      ActiveModel::Type::Boolean.new.cast(participants)
    end

    # Reload the meeting with agenda_items and outcomes preloaded
    # to ensure we have fresh data
    def reloaded_meeting
      @reloaded_meeting ||= Meeting.includes(agenda_items: :outcomes).find(meeting.id)
    end

    def generate_markdown
      lines = []

      # Add UTF-8 BOM to help content type detection
      lines << "\xEF\xBB\xBF"

      # Meeting title
      lines << "# #{meeting.title}"
      lines << ""

      # Meeting details
      lines << "**Project:** #{meeting.project.name}"
      lines << "**Date:** #{meeting.start_time.strftime("%Y-%m-%d")}"
      lines << "**Time:** #{meeting.start_time.strftime("%H:%M")}"
      lines << "**Location:** #{meeting.location}" if meeting.location.present?
      lines << ""

      # Participants section
      if with_participants? && meeting.participants.any?
        lines << "## Participants"
        meeting.participants.each do |participant|
          lines << "- #{participant.user.name}"
        end
        lines << ""
      end

      # Use reloaded meeting to get fresh agenda_items with outcomes
      agenda_items = reloaded_meeting.agenda_items

      # Agenda section
      if agenda_items.any?
        lines << "## Agenda"
        agenda_items.order(:position).each_with_index do |item, index|
          lines << "### #{index + 1}. #{agenda_item_title(item)}"

          if item.notes.present?
            lines << ""
            lines << "**#{I18n.t('activerecord.attributes.meeting_agenda_item.description')}:**"
            lines << item.notes
          end

          # Include outcomes directly under the agenda item if enabled
          if with_outcomes? && item.outcomes.any?
            lines << ""
            lines << "**Outcomes:**"
            item.outcomes.each do |outcome|
              lines.concat(outcome_lines(outcome))
            end
          end

          lines << ""
        end
      end

      lines.join("\n")
    end

    def agenda_item_title(item)
      item.respond_to?(:display_title) ? item.display_title : item.title
    end

    def outcome_lines(outcome)
      lines = []

      if outcome.work_package_kind?
        lines << "- **Task:** #{outcome_work_package_title(outcome)}"
      elsif outcome.notes.present?
        lines << "- #{outcome.notes}"
      end

      lines
    end

    def outcome_work_package_title(outcome)
      if outcome.visible_work_package?
        outcome.work_package.to_s
      elsif outcome.linked_work_package?
        I18n.t(:label_agenda_item_undisclosed_wp, id: outcome.work_package_id)
      elsif outcome.deleted_work_package?
        I18n.t(:label_agenda_item_deleted_wp)
      else
        outcome.work_package_id.to_s
      end
    end
  end
end
