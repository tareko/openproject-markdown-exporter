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

# -- load spec_helper from OpenProject core
require "spec_helper"
require "action_dispatch/http/mime_type"

# Ensure markdown MIME type is registered for request specs
Mime::Type.register "text/markdown", :markdown unless Mime::Type.lookup_by_extension(:markdown)

OpenProject::AccessControl.map do |map|
  map.project_module :meetings do
    map.permission :view_meetings,
                   { meetings: %i[generate_markdown_dialog export_markdown] },
                   permissible_on: :project
  end
end

# Load plugin engine
require_relative "../lib/open_project/meeting_markdown_export/engine"

# Manually require model
require_relative "../app/models/meeting_markdown_export"

# Manually require workers using relative paths
require_relative "../app/workers/meetings/markdown_exporter"
require_relative "../app/workers/meetings/markdown_export_job"

# Manually require components
require_relative "../app/components/meetings/exports/markdown_modal_dialog_component"
require_relative "../app/components/meetings/header_component_decorator"
require_relative "../app/components/meetings/show_component_decorator"

# Load plugin locale files
locale_file = Rails.root.join("plugins/openproject-meeting-markdown-export/config/locales/en.yml")
if File.exist?(locale_file)
  translations = YAML.load_file(locale_file)
  I18n.backend.store_translations(:en, translations.fetch("en", translations))
end

# Load support files
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }
