# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) OpenProject GmbH
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

require_relative "../spec_helper"

# Explicitly require the job to ensure it's loaded
require_relative "../../app/workers/meetings/markdown_export_job"

RSpec.describe "Meetings Markdown Export",
               :skip_csrf,
               type: :rails_request do
  let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:meeting) { create(:meeting, project:, author: user) }
  let(:role) { create(:project_role, permissions: %i[view_meetings]) }
  let(:user) do
    create(:user, member_with_permissions: { project => %i[view_meetings] })
  end

  before do
    login_as user
  end

  describe "GET #show (html)" do
    it "responds with 200" do
      get project_meeting_path(project, meeting)

      expect(response).to have_http_status(:ok)
    end

    it "does not recurse when Accept header also contains markdown" do
      get project_meeting_path(project, meeting), headers: { "Accept" => "text/markdown,text/html;q=0.9" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
    end

    it "stays stable after plugin decorator file is reloaded multiple times" do
      decorator_path = Rails.root.join("plugins/openproject-markdown-exporter/app/controllers/meetings_controller_decorator.rb")

      10.times { load decorator_path }

      expect { get project_meeting_path(project, meeting) }.not_to raise_error
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #generate_markdown_dialog" do
    let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    it "returns success" do
      get generate_markdown_dialog_project_meeting_path(project, meeting), headers: turbo_headers
      expect(response).to have_http_status(:ok)
    end

    it "returns success for HTML requests" do
      get generate_markdown_dialog_project_meeting_path(project, meeting)
      expect(response).to have_http_status(:ok)
    end

    it "renders markdown export modal dialog component" do
      get generate_markdown_dialog_project_meeting_path(project, meeting), headers: turbo_headers
      expect(response.body).to include("Export Markdown")
    end

    it "returns not found for missing meeting" do
      get generate_markdown_dialog_project_meeting_path(project, id: "999999"), headers: turbo_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #export_markdown" do
    it "creates a markdown export job" do
      expect(Meetings::MarkdownExportJob).to receive(:perform_later).and_call_original

      get export_markdown_project_meeting_path(project, meeting)

      expect(response).to redirect_to(job_status_path(MeetingMarkdownExport.last.job_status.job_id))
    end

    it "passes correct options to job" do
      expect(Meetings::MarkdownExportJob).to receive(:perform_later)
        .with(hash_including(options: hash_including(participants: "1", outcomes: "0")))
        .and_call_original

      get export_markdown_project_meeting_path(project, meeting, participants: "1", outcomes: "0")
    end

    it "prefers checked checkbox value when both 1 and 0 are submitted for outcomes" do
      expect(Meetings::MarkdownExportJob).to receive(:perform_later)
        .with(hash_including(options: hash_including(outcomes: "1")))
        .and_call_original

      # Simulate Primer checkbox behavior: both checked value "1" and hidden fallback "0" are submitted
      get export_markdown_project_meeting_path(project, meeting, outcomes: %w[1 0])
    end

    it "prefers checked checkbox value when both 1 and 0 are submitted for participants" do
      expect(Meetings::MarkdownExportJob).to receive(:perform_later)
        .with(hash_including(options: hash_including(participants: "1")))
        .and_call_original

      # Simulate Primer checkbox behavior: both checked value "1" and hidden fallback "0" are submitted
      get export_markdown_project_meeting_path(project, meeting, participants: %w[1 0])
    end

    it "uses 0 when checkbox is not checked (only 0 submitted)" do
      expect(Meetings::MarkdownExportJob).to receive(:perform_later)
        .with(hash_including(options: hash_including(outcomes: "0")))
        .and_call_original

      get export_markdown_project_meeting_path(project, meeting, outcomes: "0")
    end

    context "with outcomes included" do
      let(:agenda_item) { create(:meeting_agenda_item, meeting:, title: "Discussion Item") }
      let!(:outcome) { create(:meeting_outcome, meeting_agenda_item: agenda_item, notes: "Important decision made") }

      it "includes outcomes in the exported markdown when outcomes option is '1' via HTTP request" do
        # Simulate the actual HTTP flow: user submits form with outcomes=1
        # This tests the full decorator -> job -> exporter flow
        # We capture the job arguments to verify the full flow works
        job_args = nil
        allow(Meetings::MarkdownExportJob).to receive(:perform_later) do |**kwargs|
          job_args = kwargs
          # Actually perform the job synchronously to test the full flow
          Meetings::MarkdownExportJob.new(**kwargs).perform_now
        end

        get export_markdown_project_meeting_path(project, meeting, outcomes: "1")

        # Verify the job was called with correct options
        expect(job_args).to include(options: hash_including(outcomes: "1"))

        # Find the created export and check its attachment
        export = MeetingMarkdownExport.last
        expect(export).to be_present
        attachment = export.attachments.first
        expect(attachment).to be_present

        content = File.read(attachment.diskfile)
        expect(content).to include("**Outcomes:**")
        expect(content).to include("Important decision made")
      end

      it "includes outcomes in the exported markdown when outcomes option is '1' (direct job)" do
        # Directly execute the job to test the full flow
        job = Meetings::MarkdownExportJob.new(
          export: MeetingMarkdownExport.create,
          mime_type: :markdown,
          user:,
          query: meeting,
          outcomes: "1"
        )
        job.perform_now

        expect(job.job_status).to be_success
        attachment = job.status_reference.attachments.first
        content = File.read(attachment.diskfile)

        expect(content).to include("**Outcomes:**")
        expect(content).to include("Important decision made")
      end

      it "excludes outcomes from the exported markdown when outcomes option is '0'" do
        # Directly execute the job to test the full flow
        job = Meetings::MarkdownExportJob.new(
          export: MeetingMarkdownExport.create,
          mime_type: :markdown,
          user:,
          query: meeting,
          outcomes: "0"
        )
        job.perform_now

        expect(job.job_status).to be_success
        attachment = job.status_reference.attachments.first
        content = File.read(attachment.diskfile)

        expect(content).not_to include("**Outcomes:**")
        expect(content).not_to include("Important decision made")
      end
    end

    context "when plugin export table is missing" do
      it "falls back to core exports table and does not return 500" do
        undefined_table = PG::UndefinedTable.new("ERROR: relation \"meeting_markdown_exports\" does not exist")
        error = ActiveRecord::StatementInvalid.new("missing table")
        allow(error).to receive(:cause).and_return(undefined_table)

        allow(MeetingMarkdownExport).to receive(:create!).and_raise(error)
        expect(Meetings::MarkdownExportJob).to receive(:perform_later).and_call_original

        get export_markdown_project_meeting_path(project, meeting)

        expect(response).to redirect_to(job_status_path(Export.where(type: "MeetingMarkdownExport").last.job_status.job_id))
      end
    end

    it "returns not found for missing meeting" do
      get export_markdown_project_meeting_path(project, id: "999999")

      expect(response).to have_http_status(:not_found)
    end
  end
end
