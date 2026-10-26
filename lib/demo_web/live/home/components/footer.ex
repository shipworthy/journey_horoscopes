defmodule DemoWeb.Live.Home.Components.Footer do
  @moduledoc false

  use DemoWeb, :html
  import DemoWeb.Live.Classes

  def render(assigns) do
    ~H"""
    <div aria-label="Footer" class="flex justify-center border-t-2 p-3">
      <span>
        <span
          id="footer-about-icon-id"
          aria-label="About Us"
          class={footer_icon()}
          phx-click="on-show-about-dialog-click"
        >
          <.icon name="hero-question-mark-circle" class="h-8 w-8 " />
        </span>
        |
        <span
          id="footer-emoji-smiley-id"
          aria-label="Feedback – happy smiley face"
          class={footer_icon() <> if @feedback_emoji == "smiley", do: " bg-gold-cta rounded-xl ", else: ""}
          phx-click="on-feedback-emoji-smiley-click"
        >
          <.icon name="hero-face-smile" class="h-8 w-8 " />
        </span>
        |
        <span
          id="footer-emoji-frowney-id"
          aria-label="Feedback – frowney face"
          class={footer_icon()  <> if @feedback_emoji == "frowney", do: " bg-gold-cta rounded-xl ", else: ""}
          phx-click="on-feedback-emoji-frowney-click"
        >
          <.icon name="hero-face-frown" class="h-8 w-8" />
        </span>
        |
        <span
          id="footer-contact-icon-id"
          aria-label="Contact us"
          class={footer_icon() <> if @feedback_text != "", do: " bg-gold-cta rounded-xl ", else: "" }
          phx-click="on-show-contact-us-dialog-click"
        >
          <.icon name="hero-envelope" class="h-8 w-8" />
        </span>
      </span>
    </div>
    """
  end
end
