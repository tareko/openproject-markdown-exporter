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

# Manually require the component
require_relative "../../../../app/components/meetings/exports/markdown_modal_dialog_component"

RSpec.describe Meetings::Exports::MarkdownModalDialogComponent, type: :component do
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project, name: "Test Project") }
  let(:meeting) do
    build_stubbed(:meeting, project:, title: "Test Meeting", author: user)
  end
  let(:component) do
    described_class.new(meeting:, project:)
  end

  before do
    # Store translations for component tests
    I18n.backend.store_translations(:en,
      label_export_markdown: "Export Markdown",
      meeting: {
        export_markdown_dialog: {
          description: "Export meeting as Markdown",
          include_participants: {
            label: "Include participants",
            caption: "Add a list of meeting participants"
          },
          include_outcomes: {
            label: "Include outcomes",
            caption: "Add meeting outcomes/decisions"
          },
          submit_button: "Download"
        }
      }
    )
  end

  it "renders modal dialog" do
    render_inline(component)

    expect(rendered_content).to include("Export Markdown")
    expect(rendered_content).to include("Export meeting as Markdown")
  end

  it "includes participants checkbox" do
    render_inline(component)

    expect(rendered_content).to include("md_include_participants")
    expect(rendered_content).to include("Include participants")
  end

  it "includes outcomes checkbox" do
    render_inline(component)

    expect(rendered_content).to include("md_include_outcomes")
    expect(rendered_content).to include("Include outcomes")
  end

  it "has correct form action" do
    render_inline(component)

    # Check that the form action is set (without verifying exact path since routes may not be loaded)
    expect(rendered_content).to match(/action="\/projects\/[\w_]+\/meetings\/\d+\.markdown"/)
  end
end
