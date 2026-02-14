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

require "spec_helper"

# Explicitly require the exporter class using relative path
require_relative "../../../app/workers/meetings/markdown_exporter"

RSpec.describe Meetings::MarkdownExporter do
  let(:user) { create(:user) }
  let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:meeting) do
    create :meeting,
           project:,
           start_time: "2024-12-31T13:30:00Z",
           duration: 1.5,
           title: "Test Meeting",
           location: "Room 101",
           author: user
  end

  before do
    mock_permissions_for(user, &:allow_everything)
  end

  describe "#export!" do
    it "generates markdown content successfully" do
      exporter = described_class.new(meeting, current_user: user)
      result = exporter.export!

      expect(result).to be_a(Exports::Result)
      expect(result.format).to eq(:markdown)
      expect(result.mime_type).to eq("text/markdown")
      expect(result.title).to end_with(".md")
      expect(result.content).to be_a(String)
    end

    it "includes meeting title in markdown" do
      exporter = described_class.new(meeting, current_user: user)
      result = exporter.export!

      expect(result.content).to include("# Test Meeting")
    end

    it "includes project name in markdown" do
      exporter = described_class.new(meeting, current_user: user)
      result = exporter.export!

      expect(result.content).to include("**Project:** #{project.name}")
    end

    it "includes date and time in markdown" do
      exporter = described_class.new(meeting, current_user: user)
      result = exporter.export!

      expect(result.content).to match(/\*\*Date:\*\* 2024-12-31/)
      expect(result.content).to match(/\*\*Time:\*\* 13:30/)
    end

    it "includes location in markdown" do
      exporter = described_class.new(meeting, current_user: user)
      result = exporter.export!

      expect(result.content).to include("**Location:** Room 101")
    end

    context "with participants" do
      before do
        create(:meeting_participant, meeting:, user:)
        meeting.reload
      end

      it "includes participants section when option is enabled" do
        exporter = described_class.new(meeting, current_user: user, participants: true)
        result = exporter.export!

        expect(result.content).to include("## Participants")
      end

      it "excludes participants section when option is disabled" do
        exporter = described_class.new(meeting, current_user: user, participants: false)
        result = exporter.export!

        expect(result.content).not_to include("## Participants")
      end

      it "includes participants section when option is string '1' (from checkbox)" do
        exporter = described_class.new(meeting, current_user: user, participants: "1")
        result = exporter.export!

        expect(result.content).to include("## Participants")
      end

      it "excludes participants section when option is string '0' (from checkbox)" do
        exporter = described_class.new(meeting, current_user: user, participants: "0")
        result = exporter.export!

        expect(result.content).not_to include("## Participants")
      end
    end

    context "with agenda items" do
      before do
        create(:meeting_agenda_item, meeting:, title: "Agenda Item 1")
      end

      it "includes agenda section" do
        exporter = described_class.new(meeting, current_user: user)
        result = exporter.export!

        expect(result.content).to include("## Agenda")
        expect(result.content).to include("### 1. Agenda Item 1")
      end
    end

    context "with outcomes" do
      before do
        agenda_item = create(:meeting_agenda_item, meeting:, title: "Agenda Item 1", notes: "Agenda description")
        create(:meeting_outcome, meeting_agenda_item: agenda_item, notes: "Outcome notes")
      end

      it "includes outcomes when option is enabled" do
        exporter = described_class.new(meeting, current_user: user, outcomes: true)
        result = exporter.export!

        expect(result.content).to include("**Outcomes:**")
        expect(result.content).to include("Outcome notes")
      end

      it "excludes outcomes when option is disabled" do
        exporter = described_class.new(meeting, current_user: user, outcomes: false)
        result = exporter.export!

        expect(result.content).not_to include("**Outcomes:**")
        expect(result.content).not_to include("Outcome notes")
      end

      it "includes outcomes when option is string '1' (from checkbox)" do
        exporter = described_class.new(meeting, current_user: user, outcomes: "1")
        result = exporter.export!

        expect(result.content).to include("**Outcomes:**")
        expect(result.content).to include("Outcome notes")
      end

      it "excludes outcomes when option is string '0' (from checkbox)" do
        exporter = described_class.new(meeting, current_user: user, outcomes: "0")
        result = exporter.export!

        expect(result.content).not_to include("**Outcomes:**")
        expect(result.content).not_to include("Outcome notes")
      end

      it "includes agenda item descriptions" do
        exporter = described_class.new(meeting, current_user: user, outcomes: true)
        result = exporter.export!

        expect(result.content).to include("**Notes:**")
        expect(result.content).to include("Agenda description")
      end

      it "includes work package outcomes as tasks" do
        agenda_item = create(:meeting_agenda_item, meeting:, title: "Agenda Item 2")
        work_package = create(:work_package, project: meeting.project)
        create(:meeting_outcome, meeting_agenda_item: agenda_item, kind: :work_package, work_package:)

        exporter = described_class.new(meeting, current_user: user, outcomes: true)
        result = exporter.export!

        expect(result.content).to include("- **Task:**")
        expect(result.content).to include(I18n.t(:label_agenda_item_undisclosed_wp, id: work_package.id))
      end
    end
  end
end
