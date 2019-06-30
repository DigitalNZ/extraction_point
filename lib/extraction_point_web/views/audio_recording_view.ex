defmodule ExtractionPointWeb.AudioRecordingView do
  use ExtractionPointWeb, :view
  alias ExtractionPointWeb.AudioRecordingView

  def render("index.json", %{audio_recordings: audio_recordings, meta: meta}) do
    %{meta: meta, data: render_many(audio_recordings, AudioRecordingView, "audio_recording.json")}
  end

  def render("show.json", %{audio_recording: audio_recording}) do
    %{data: render_one(audio_recording, AudioRecordingView, "audio_recording.json")}
  end

  def render("audio_recording.json", %{audio_recording: audio_recording}) do
    audio_recording
  end
end
