defmodule Bep.PublicationControllerTest do
  use Bep.ConnCase

  test "Save publication - Returns 500 payload mal formed", %{conn: conn} do
    search = insert_search()
    conn = post conn, publication_path(
      conn,
      :create, %{"search_id": "#{search.id}", tripdatabase_id: "1"}
    )
    assert json_response(conn, 500)
  end
end
