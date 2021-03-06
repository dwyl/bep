defmodule Bep.EvidenceChannel do
  use Bep.Web, :channel
  alias Bep.{Publication, User, Tripdatabase.HTTPClient, Repo, Search}
  import Phoenix.View, only: [render_to_string: 3]

  def join("evidence:" <> search_id, _params, socket) do
    init_socket = socket
    |> assign(:page, 1)
    |> assign(:search_id, String.to_integer(search_id))
    {:ok, init_socket}
  end

  # get extract user schema from socket
  def handle_in(event, params, socket) do
    user = Repo.get(User, socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  # event received when a user clicked on a publication
  def handle_in("evidence", params, _user, socket) do
    case save_publication(params) do
      {:ok, publication} ->
        res = {:ok, %{publication_id: publication.id}}
        {:reply, res, socket}
      {:error, %{changes: %{searches: [%{errors: error}]}}} ->
        err = {:searches, {"Search already exists for this publication", []}}
        if List.first(error) == err do
          tripdatabase_id =  params["tripdatabase_id"]
          pub = Repo.get_by!(Publication, tripdatabase_id: tripdatabase_id)
          res = {:ok, %{publication_id: pub.id}}
          {:reply, res, socket}
        else
          {:reply, {:error, %{error: "save publication failed"}}, socket}
        end
      {:error, _changeset} ->
        {:reply, {:error, %{error: "save publication failed"}}, socket}
    end
  end

  def handle_in("scroll", params, user, socket) do
    page = socket.assigns.page
    html = load_page(socket, %{term: params["term"]}, user)
    update_socket = assign(socket, :page, page  + 1)
    data = %{
      page: update_socket.assigns.page,
      content: html
    }
    {:reply, {:ok, data}, update_socket}
  end

  defp save_publication(payload) do
    changeset = Publication.changeset(%Publication{}, payload)
    tripdatabase_id = changeset.changes.tripdatabase_id

    Repo.insert(
      changeset,
      on_conflict: [set: [tripdatabase_id:	tripdatabase_id]],
      conflict_target:	:tripdatabase_id
    )
  end

  defp load_page(socket, %{term: term}, user) do
    search = Repo.get_by!(Search, term: term)
    skip = socket.assigns.page * 20
    {:ok, data} = HTTPClient.search(term, %{skip: skip})

    tripdatabase_ids = Enum.map(data["documents"], &(&1["id"]))
    pubs = Search.get_publications(user, tripdatabase_ids)
    data = Search.link_publication_notes(data, pubs)
    assigns = [
      data: data,
      start: skip + 1,
      id: socket.assigns.search_id,
      uncertainty: search.uncertainty

    ]

    render_to_string(Bep.SearchView, "evidences.html", assigns)
  end

end
