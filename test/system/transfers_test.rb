require "application_system_test_case"

class TransfersTest < ApplicationSystemTestCase
  setup do
    @transfer = transfers(:one)
  end

  test "visiting the index" do
    visit transfers_url
    assert_selector "h1", text: "Transfers"
  end

  test "should create transfer" do
    visit transfers_url
    click_on "New transfer"

    fill_in "Cantidad", with: @transfer.cantidad
    fill_in "Desde", with: @transfer.desde
    fill_in "Fecha", with: @transfer.fecha
    fill_in "Hacia", with: @transfer.hacia
    fill_in "Motivo", with: @transfer.motivo
    fill_in "Tipo", with: @transfer.tipo
    fill_in "User", with: @transfer.user_id
    click_on "Create Transfer"

    assert_text "Transfer was successfully created"
    click_on "Back"
  end

  test "should update Transfer" do
    visit transfer_url(@transfer)
    click_on "Edit this transfer", match: :first

    fill_in "Cantidad", with: @transfer.cantidad
    fill_in "Desde", with: @transfer.desde
    fill_in "Fecha", with: @transfer.fecha
    fill_in "Hacia", with: @transfer.hacia
    fill_in "Motivo", with: @transfer.motivo
    fill_in "Tipo", with: @transfer.tipo
    fill_in "User", with: @transfer.user_id
    click_on "Update Transfer"

    assert_text "Transfer was successfully updated"
    click_on "Back"
  end

  test "should destroy Transfer" do
    visit transfer_url(@transfer)
    click_on "Destroy this transfer", match: :first

    assert_text "Transfer was successfully destroyed"
  end
end
