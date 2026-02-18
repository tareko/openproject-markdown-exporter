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

require "open_project/meeting_markdown_export/version"

module OpenProject
  module MeetingMarkdownExport
    class Engine < ::Rails::Engine
      engine_name :openproject_meeting_markdown_export

      include OpenProject::Plugins::ActsAsOpEngine

      register "openproject-meeting_markdown_export",
               author_url: "https://www.openproject.org",
               bundled: false do
        project_module :meetings do
          permission :view_meetings,
                     { meetings: %i[generate_markdown_dialog export_markdown] },
                     permissible_on: :project
        end
      end

      initializer "openproject-meeting_markdown_export.mime_type" do
        Mime::Type.register "text/markdown", :markdown unless Mime::Type.lookup_by_extension(:markdown)
      end

      config.autoload_paths += Dir[
        "#{root}/app/workers",
        "#{root}/app/components",
        "#{root}/app/controllers"
      ]

      config.eager_load_paths += Dir[
        "#{root}/app/controllers"
      ]

      config.to_prepare do
        OpenProject::AccessControl.map do |map|
          map.project_module :meetings do
            map.permission :view_meetings,
                           { meetings: %i[generate_markdown_dialog export_markdown] },
                           permissible_on: :project
          end
        end

        # Ensure the base controller is loaded before applying the decorator
        require_dependency "meetings_controller"

        # Require decorator files to ensure they are loaded
        require_dependency File.join(OpenProject::MeetingMarkdownExport::Engine.root, "app/controllers/meetings_controller_decorator")
        require_dependency File.join(OpenProject::MeetingMarkdownExport::Engine.root, "app/components/meetings/show_component_decorator")
        require_dependency File.join(OpenProject::MeetingMarkdownExport::Engine.root, "app/components/meetings/header_component_decorator")

        unless MeetingsController.ancestors.any? { |ancestor| ancestor.name == "MeetingsControllerDecorator" }
          MeetingsController.include(MeetingsControllerDecorator)
        end

        # Require workers to ensure they are loaded
        require_relative "../../../app/workers/meetings/markdown_exporter"
        require_relative "../../../app/workers/meetings/markdown_export_job"

        # Ensure core components are loaded before overriding identifiers
        require_dependency "meetings/show_component"
        require_dependency "meetings/header_component"

        # Override component identifiers to use plugin sidecar templates
        ::Meetings::ShowComponent.send(
          :identifier=,
          OpenProject::MeetingMarkdownExport::Engine.root
            .join("app/components/meetings/show_component.rb")
            .to_s
        )

        ::Meetings::HeaderComponent.send(
          :identifier=,
          OpenProject::MeetingMarkdownExport::Engine.root
            .join("app/components/meetings/header_component.rb")
            .to_s
        )

        ::Meetings::ShowComponent.__vc_compile(force: true)
        ::Meetings::HeaderComponent.__vc_compile(force: true)

        ::Exports::Register.register do
          single(::Meeting, ::Meetings::MarkdownExporter)
        end
      end
    end
  end
end
