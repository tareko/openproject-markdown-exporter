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

# Explicitly require the engine
require_relative "../../../../lib/open_project/meeting_markdown_export/engine"
# Require the markdown_exporter to ensure it's loaded
require_relative "../../../../app/workers/meetings/markdown_exporter"

RSpec.describe OpenProject::MeetingMarkdownExport::Engine do
  before do
    # Manually register the markdown exporter for testing
    Exports::Register.register do
      single(::Meeting, Meetings::MarkdownExporter)
    end
  end

  it "registers the markdown exporter for Meeting model" do
    exporter = Exports::Register.single_exporter(::Meeting, :markdown)
    expect(exporter).to eq(Meetings::MarkdownExporter)
  end

  it "includes markdown in available export formats" do
    formats = Exports::Register.single_formats(::Meeting)
    expect(formats).to include(:markdown)
  end
end
