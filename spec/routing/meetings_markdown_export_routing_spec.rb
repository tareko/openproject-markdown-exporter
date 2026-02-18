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

require_relative "../spec_helper"

RSpec.describe "meetings markdown export routes", type: :routing do
  it "registers generate_markdown_dialog route helper and route" do
    expect(Rails.application.routes.url_helpers.instance_methods)
      .to include(:generate_markdown_dialog_project_meeting_path)

    expect(get("/projects/demo-project/meetings/42/generate_markdown_dialog"))
      .to route_to(controller: "meetings", action: "generate_markdown_dialog", project_id: "demo-project", id: "42")
  end

  it "registers export_markdown route helper and route" do
    expect(Rails.application.routes.url_helpers.instance_methods)
      .to include(:export_markdown_project_meeting_path)

    expect(get("/projects/demo-project/meetings/42/export_markdown"))
      .to route_to(controller: "meetings", action: "export_markdown", project_id: "demo-project", id: "42")
  end
end
