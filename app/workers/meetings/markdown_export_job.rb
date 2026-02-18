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
  class MarkdownExportJob < ::Exports::ExportJob
    self.model = ::Meeting

    def title
      "Meeting Markdown export"
    end

    def prepare!; end

    def list_export?
      false
    end

    private

    def exporter_single_list
      # Handle both direct kwargs (from tests) and nested options (from perform_later)
      # When called via perform_later with options: {outcomes: "1"}, options[:options] contains the actual options
      # When called directly with outcomes: "1", options[:outcomes] contains the actual value
      opts = options[:options] || options

      ::Exports::Register
        .single_exporter(model, mime_type)
        .new(query, current_user: current_user, participants: opts[:participants], outcomes: opts[:outcomes])
    end

    def store_attachment(container, file, export_result)
      filename = clean_filename(export_result)

      call = Attachments::CreateService
               .bypass_allowlist(user: User.current)
               .call(container:, file:, filename:, description: "")

      call.on_success do
        download_url = ::API::V3::Utilities::PathHelper::ApiV3Path.attachment_content(call.result.id)

        upsert_status status: :success,
                      message: I18n.t("export.succeeded"),
                      payload: download_payload(download_url, export_result.mime_type)
      end

      call.on_failure do
        upsert_status status: :failure,
                      message: I18n.t("export.failed", message: call.message)
      end
    end
  end
end
