defmodule ExtractionPointWeb.WebLinkControllerTest do
  use ExtractionPointWeb.ConnCase

  alias ExtractionPoint.WebLinks
  alias ExtractionPoint.WebLinks.WebLink

  @create_attrs %{

  }
  @update_attrs %{

  }
  @invalid_attrs %{}

  def fixture(:web_link) do
    {:ok, web_link} = WebLinks.create_web_link(@create_attrs)
    web_link
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all web_links", %{conn: conn} do
      conn = get(conn, Routes.web_link_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create web_link" do
    test "renders web_link when data is valid", %{conn: conn} do
      conn = post(conn, Routes.web_link_path(conn, :create), web_link: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.web_link_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.web_link_path(conn, :create), web_link: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update web_link" do
    setup [:create_web_link]

    test "renders web_link when data is valid", %{conn: conn, web_link: %WebLink{id: id} = web_link} do
      conn = put(conn, Routes.web_link_path(conn, :update, web_link), web_link: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.web_link_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, web_link: web_link} do
      conn = put(conn, Routes.web_link_path(conn, :update, web_link), web_link: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete web_link" do
    setup [:create_web_link]

    test "deletes chosen web_link", %{conn: conn, web_link: web_link} do
      conn = delete(conn, Routes.web_link_path(conn, :delete, web_link))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.web_link_path(conn, :show, web_link))
      end
    end
  end

  defp create_web_link(_) do
    web_link = fixture(:web_link)
    {:ok, web_link: web_link}
  end
end
