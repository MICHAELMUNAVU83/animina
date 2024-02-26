defmodule AniminaWeb.ProfilePhotoLive do
  use AniminaWeb, :live_view

  alias AniminaWeb.Registration

  alias Animina.Accounts
  alias Animina.Accounts.Photo
  alias AshPhoenix.Form

  @impl true
  def mount(_params, session, socket) do
    current_user =
      case Registration.get_current_user(session) do
        nil ->
          redirect(socket, to: "/")

        user ->
          user
      end

    socket =
      socket
      |> assign(current_user: current_user)
      |> assign(active_tab: :home)
      |> assign(page_title: gettext("Upload a profile photo"))
      |> allow_upload(:photo, accept: ~w(.jpg .jpeg .png), max_entries: 1, id: "audio_file")
      |> assign(
        :form,
        Form.for_create(Photo, :create, api: Accounts, as: "photo")
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_photo", %{"photo" => params}, socket) do
    form = Form.validate(socket.assigns.form, params, errors: true)

    {:noreply, socket |> assign(:form, form)}
  end

  @impl true
  def handle_event("select_photo", %{"photo" => params}, socket) do
    form = Form.validate(socket.assigns.form, params, errors: true)

    {:noreply, socket |> assign(:form, form)}
  end

  @impl true
  def handle_event("submit_photo", %{"photo" => params}, socket) do
    consume_uploaded_entries(socket, :photo, fn _meta, entry ->
      {:ok,
       %{
         "filename" => entry.uuid <> "." <> ext(entry),
         "original_filename" => entry.client_name,
         "ext" => ext(entry),
         "mime" => entry.client_type,
         "size" => entry.client_size
       }}
    end)
    |> case do
      [] ->
        {:noreply, socket}

      [%{} = file] ->
        params = Map.merge(params, file)
        form = Form.validate(socket.assigns.form, params, errors: true)

        with [] <- Form.errors(form), {:ok, _photo} <- Form.submit(form, params: params) do
          {:noreply,
           socket
           |> assign(:errors, [])
           |> assign(
             :form,
             Form.for_create(Photo, :create, api: Accounts, as: "photo")
           )}
        else
          {:error, form} ->
            {:noreply, socket |> assign(:form, form)}

          errors ->
            {:noreply, socket |> assign(:errors, errors)}
        end
    end
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref, "value" => _value}, socket) do
    {:noreply,
     socket
     |> cancel_upload(:photo, ref)
     |> assign(
       :form,
       Form.for_create(Photo, :create, api: Accounts, as: "photo")
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-10 px-5">
      <.notification_box
        title={gettext("Hello %{name}!", name: @current_user.name)}
        message={gettext("To complete your profile upload a profile photo")}
      />

      <h2 class="font-bold text-xl"><%= gettext("Select or use camera to take a photo") %></h2>

      <.form
        :let={f}
        for={@form}
        class="space-y-6"
        phx-change="validate_photo"
        phx-submit="submit_photo"
      >
        <div class="hidden">
          <.live_file_input
            type="file"
            accept="image/*"
            upload={@uploads.photo}
            class="hidden pointer-events-none"
          />
        </div>

        <%= text_input(f, :user_id, type: :hidden, value: @current_user.id) %>

        <div
          :if={Enum.count(@uploads.photo.entries) == 0}
          phx-click={JS.dispatch("click", to: "##{@uploads.photo.ref}", bubbles: false)}
          phx-drop-target={@uploads.photo.ref}
          for={@uploads.photo.ref}
          class="flex flex-col items-center max-w-2xl w-full py-8 px-6 mx-auto  text-center border-2 border-gray-300 border-dashed cursor-pointer bg-gray-50  rounded-md"
        >
          <.icon name="hero-cloud-arrow-up" class="w-8 h-8 mb-4 text-gray-500 dark:text-gray-400" />

          <p class="text-sm">Upload or drag & drop your photo file JPG, JPEG, PNG</p>
        </div>

        <%= for entry <- @uploads.photo.entries do %>
          <%= text_input(f, :filename, type: :hidden, value: entry.uuid <> "." <> ext(entry)) %>
          <%= text_input(f, :original_filename, type: :hidden, value: entry.client_name) %>
          <%= text_input(f, :ext, type: :hidden, value: ext(entry)) %>
          <%= text_input(f, :mime, type: :hidden, value: entry.client_type) %>
          <%= text_input(f, :size, type: :hidden, value: entry.client_size) %>

          <div
            phx-mounted={
              JS.push("select_photo",
                value: %{
                  photo: %{
                    filename: entry.uuid <> "." <> ext(entry),
                    original_filename: entry.client_name,
                    ext: ext(entry),
                    user_id: @current_user.id,
                    mime: entry.client_type,
                    size: entry.client_size
                  }
                }
              )
            }
            class="flex space-x-8"
          >
            <.live_img_preview class="inline-block object-cover h-32 w-32 rounded-md" entry={entry} />

            <div class="flex-1 flex flex-col justify-center">
              <p><%= entry.client_name %></p>
              <p class="text-sm text-gray-600">
                <%= Size.humanize!(entry.client_size, output: :string) %>
              </p>

              <div class="mt-4">
                <button
                  type="button"
                  class="flex w-24 justify-center rounded-md border border-red-600 bg-red-100 px-3 py-1.5 text-sm font-semibold shadow-none leading-6 text-red-600 hover:bg-red-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
                  phx-click="cancel_upload"
                  phx-value-ref={entry.ref}
                  aria-label="cancel"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>

          <div :if={Enum.count(upload_errors(@uploads.photo, entry))} class="danger mb-4" role="alert">
            <ul class="error-messages">
              <%= for err <- upload_errors(@uploads.photo, entry) do %>
                <li>
                  <p><%= error_to_string(err) %></p>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>

        <div>
          <%= submit(gettext("Upload"),
            class:
              "flex w-full justify-center rounded-md bg-indigo-600 px-3 py-1.5 text-sm font-semibold leading-6 text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 " <>
                unless(@form.valid? == false,
                  do: "",
                  else: "opacity-40 cursor-not-allowed hover:bg-blue-500 active:bg-blue-500"
                ),
            disabled: @form.valid? == false
          ) %>
        </div>
      </.form>
    </div>
    """
  end

  defp error_to_string(:too_large), do: gettext("Too large")
  defp error_to_string(:not_accepted), do: gettext("You have selected an unacceptable file type")
  defp error_to_string(:too_many_files), do: gettext("You have selected too many files")

  defp error_to_string(_),
    do: gettext("Something went wrong uploading your photo. Try again")

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end
end