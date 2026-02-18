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

# Explicitly require the job class using relative path
require_relative "../../../app/workers/meetings/markdown_export_job"

# Explicitly require the model
require_relative "../../../app/models/meeting_markdown_export"

RSpec.describe Meetings::MarkdownExportJob do
  let(:user) { build_stubbed(:user) }
  let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:meeting) do
    create :meeting,
           project:,
           start_time: "2024-12-31T13:30:00Z",
           duration: 1.5,
           author: user
  end

  before do
    mock_permissions_for(user, &:allow_everything)
    # Manually trigger the registration in case it's not loaded yet
    ::Exports::Register.register do
      single(::Meeting, ::Meetings::MarkdownExporter)
    end
  end

  def perform_meeting_export(options = {})
    job = described_class.new(
      export: MeetingMarkdownExport.create,
      mime_type: :markdown,
      user: user,
      query: meeting,
      **options
    )
    job.perform_now
    job
  end

  RSpec::Matchers.define :have_one_attachment_with_content_type do |expected_content_type|
    def attachments(export_job)
      export_job.status_reference.attachments
    end

    match do |export_job|
      attachments_content_types = attachments(export_job).pluck(:content_type)
      attachments_content_types == [expected_content_type]
    end

    failure_message do |export_job|
      attachments_content_types = attachments(export_job).pluck(:content_type)
      "expected that #{actual} would have one attachment with mime type #{expected.inspect}, " \
        "got #{attachments_content_types.inspect} instead"
    end
  end

  it "generates a markdown export successfully" do
    job = perform_meeting_export

    expect(job.job_status).to be_success, job.job_status.message
    expect(job).to have_one_attachment_with_content_type("text/markdown")
  end

  it "uses the core attachment create service" do
    expect(Attachments::CreateService).to receive(:bypass_allowlist).and_call_original

    job = perform_meeting_export
    expect(job.job_status).to be_success, job.job_status.message
  end

  it "creates an export with correct filename" do
    job = perform_meeting_export
    attachment = job.status_reference.attachments.first

    expect(attachment.filename.to_s).to end_with(".md")
  end

  context "when outcomes option is enabled" do
    let(:meeting) do
      create :meeting,
             project:,
             start_time: "2024-12-31T13:30:00Z",
             duration: 1.5,
             author: user,
             title: "Meeting with Outcomes"
    end
    let!(:agenda_item) { create(:meeting_agenda_item, meeting:, title: "Discussion Item") }
    let!(:outcome) { create(:meeting_outcome, meeting_agenda_item: agenda_item, notes: "Important decision made") }

    it "includes outcomes in the exported markdown when outcomes option is '1'" do
      job = perform_meeting_export(outcomes: "1")

      expect(job.job_status).to be_success, job.job_status.message
      attachment = job.status_reference.attachments.first
      content = File.read(attachment.diskfile)

      expect(content).to include("**Outcomes:**")
      expect(content).to include("Important decision made")
    end

    it "excludes outcomes from the exported markdown when outcomes option is '0'" do
      job = perform_meeting_export(outcomes: "0")

      expect(job.job_status).to be_success, job.job_status.message
      attachment = job.status_reference.attachments.first
      content = File.read(attachment.diskfile)

      expect(content).not_to include("**Outcomes:**")
      expect(content).not_to include("Important decision made")
    end
  end
end
