# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Meeting Markdown Export - Show Component Override", type: :request do
  describe "ShowComponent template override" do
    it "overrides the component identifier to use the plugin template" do
      # Verify that the ShowComponent's identifier points to the plugin component file
      expect(::Meetings::ShowComponent.identifier)
        .to end_with("plugins/openproject-meeting-markdown-export/app/components/meetings/show_component.rb")
    end
  end
end
