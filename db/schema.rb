# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_10_23_154722) do
  create_table "auth_tokens", force: :cascade do |t|
    t.string "rnc", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "token_digest", null: false
    t.index ["rnc"], name: "index_auth_tokens_on_rnc"
    t.index ["token_digest"], name: "index_auth_tokens_on_token_digest", unique: true
  end

  create_table "electronic_invoices", force: :cascade do |t|
    t.string "track_id", null: false
    t.string "rnc_emisor", null: false
    t.string "encf", null: false
    t.string "tipo_comprobante"
    t.date "fecha_emision"
    t.text "xml_content"
    t.string "estado", null: false
    t.datetime "fecha_recepcion", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["encf"], name: "index_electronic_invoices_on_encf"
    t.index ["rnc_emisor", "encf"], name: "index_electronic_invoices_on_rnc_emisor_and_encf", unique: true
    t.index ["rnc_emisor"], name: "index_electronic_invoices_on_rnc_emisor"
    t.index ["track_id"], name: "index_electronic_invoices_on_track_id", unique: true
  end

  create_table "validation_errors", force: :cascade do |t|
    t.integer "electronic_invoice_id", null: false
    t.string "codigo", null: false
    t.string "campo", null: false
    t.text "mensaje", null: false
    t.string "severidad", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["codigo"], name: "index_validation_errors_on_codigo"
    t.index ["electronic_invoice_id"], name: "index_validation_errors_on_electronic_invoice_id"
  end

  add_foreign_key "validation_errors", "electronic_invoices"
end
