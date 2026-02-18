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

module MeetingsControllerDecorator
  def self.included(base)
    base.class_eval do
      respond_to :markdown

      def generate_markdown_dialog
        respond_to do |format|
          format.turbo_stream do
            respond_with_dialog Meetings::Exports::MarkdownModalDialogComponent.new(meeting: @meeting, project: @project)
          end
          format.html do
            render Meetings::Exports::MarkdownModalDialogComponent.new(meeting: @meeting, project: @project),
                   layout: false
          end
        end
      end

      def export_markdown
        export = create_markdown_export!
        job = ::Meetings::MarkdownExportJob.perform_later(
          export: export,
          user: current_user,
          mime_type: :markdown,
          query: @meeting,
          options: markdown_export_options
        )

        if request.headers["Accept"]&.include?("application/json")
          render json: { job_id: job.job_id }
        else
          redirect_to job_status_path(job.job_id)
        end
      end

      private

      def markdown_export_options
        options = params.to_unsafe_h.symbolize_keys

        participants = normalize_checkbox_option(options.delete(:md_include_participants) || options[:participants])
        outcomes = normalize_checkbox_option(options.delete(:md_include_outcomes) || options[:outcomes])

        options[:participants] = participants if participants.present?
        options[:outcomes] = outcomes if outcomes.present?

        options.slice(:participants, :outcomes)
      end

      def normalize_checkbox_option(value)
        return if value.nil?

        # When Primer checkboxes are used, both the checkbox value ("1" when checked)
        # and a hidden fallback ("0") are submitted. Prefer "1" over "0" to respect
        # the checked state.
        if value.is_a?(Array)
          value.include?("1") ? "1" : value.last
        else
          value
        end
      end

      def create_markdown_export!
        MeetingMarkdownExport.create!
      rescue ActiveRecord::StatementInvalid => e
        raise unless missing_plugin_export_table?(e)

        # Fallback for environments where a separate plugin table is not present.
        # Persist through the core exports table while keeping the STI type.
        Export.create!(type: "MeetingMarkdownExport")
      end

      def missing_plugin_export_table?(error)
        cause = error.cause
        return false unless cause.is_a?(PG::UndefinedTable)

        cause.message.include?("meeting_markdown_exports")
      end
    end
  end
end
