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

ActiveRecord::Schema[8.0].define(version: 2026_10_26_150004) do
  create_table "allowed_origins", force: :cascade do |t|
    t.string "origin", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_allowed_origins_on_deleted_at"
    t.index ["origin"], name: "index_allowed_origins_on_origin", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "actor", null: false
    t.string "action", null: false
    t.string "target"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["actor"], name: "index_audit_logs_on_actor"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["deleted_at"], name: "index_audit_logs_on_deleted_at"
  end

  create_table "auth_seeds", force: :cascade do |t|
    t.string "valor", null: false
    t.datetime "fecha", null: false
    t.datetime "expira", null: false
    t.boolean "usado", default: false, null: false
    t.string "rnc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["valor"], name: "index_auth_seeds_on_valor", unique: true
  end

  create_table "auth_tokens", force: :cascade do |t|
    t.string "rnc", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "token_digest", null: false
    t.datetime "deleted_at"
    t.integer "user_id"
    t.index ["deleted_at"], name: "index_auth_tokens_on_deleted_at"
    t.index ["rnc"], name: "index_auth_tokens_on_rnc"
    t.index ["token_digest"], name: "index_auth_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_auth_tokens_on_user_id"
  end

  create_table "certificates", force: :cascade do |t|
    t.string "rnc", null: false
    t.string "alias_name"
    t.string "subject"
    t.string "issuer"
    t.string "serial"
    t.datetime "not_before"
    t.datetime "not_after"
    t.string "thumbprint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.text "certificate_pem"
    t.boolean "active", default: true, null: false
    t.integer "company_id"
    t.index ["company_id", "active"], name: "index_certificates_on_company_id_and_active"
    t.index ["company_id"], name: "index_certificates_on_company_id"
    t.index ["deleted_at"], name: "index_certificates_on_deleted_at"
    t.index ["rnc"], name: "index_certificates_active_rnc", unique: true, where: "active = 1 AND deleted_at IS NULL"
    t.index ["rnc"], name: "index_certificates_on_rnc"
    t.index ["thumbprint"], name: "index_certificates_on_thumbprint", unique: true
  end

  create_table "commercial_approvals", force: :cascade do |t|
    t.string "rnc_emisor"
    t.string "rnc_comprador"
    t.string "encf"
    t.integer "estado"
    t.string "motivo_rechazo"
    t.datetime "fecha_hora_aprobacion"
    t.text "xml_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  create_table "companies", force: :cascade do |t|
    t.string "rnc", null: false
    t.string "razon_social"
    t.string "nombre_comercial"
    t.string "email"
    t.string "telefono"
    t.boolean "activa", default: true, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_companies_on_deleted_at"
    t.index ["rnc"], name: "index_companies_on_rnc", unique: true
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
    t.datetime "deleted_at"
    t.string "rnc_comprador"
    t.decimal "monto_total", precision: 18, scale: 2
    t.decimal "total_itbis", precision: 18, scale: 2
    t.string "fecha_firma"
    t.string "codigo_seguridad"
    t.boolean "secuencia_utilizada", default: true, null: false
    t.integer "company_id"
    t.index ["company_id", "rnc_emisor"], name: "index_electronic_invoices_on_company_id_and_rnc_emisor"
    t.index ["company_id"], name: "index_electronic_invoices_on_company_id"
    t.index ["deleted_at"], name: "index_electronic_invoices_on_deleted_at"
    t.index ["encf"], name: "index_electronic_invoices_on_encf"
    t.index ["rnc_emisor", "encf"], name: "index_electronic_invoices_on_rnc_emisor_and_encf"
    t.index ["rnc_emisor"], name: "index_electronic_invoices_on_rnc_emisor"
    t.index ["track_id"], name: "index_electronic_invoices_on_track_id", unique: true
  end

  create_table "invoice_summaries", force: :cascade do |t|
    t.string "rnc_emisor"
    t.string "encf"
    t.integer "codigo"
    t.string "estado"
    t.boolean "secuencia_utilizada"
    t.text "xml_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  create_table "ncf_annulations", force: :cascade do |t|
    t.string "rnc_emisor"
    t.integer "cantidad_anulados"
    t.datetime "fecha_hora_anulacion"
    t.text "xml_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  create_table "ncf_annulled_ranges", force: :cascade do |t|
    t.string "rnc", null: false
    t.integer "tipo", null: false
    t.integer "desde", null: false
    t.integer "hasta", null: false
    t.integer "ncf_annulation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ncf_annulation_id"], name: "index_ncf_annulled_ranges_on_ncf_annulation_id"
    t.index ["rnc", "tipo"], name: "index_ncf_annulled_ranges_on_rnc_and_tipo"
  end

  create_table "ncf_sequences", force: :cascade do |t|
    t.string "rnc", null: false
    t.integer "tipo", null: false
    t.integer "desde", null: false
    t.integer "hasta", null: false
    t.date "fecha_vencimiento", null: false
    t.boolean "activa", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "anulada", default: false, null: false
    t.integer "company_id"
    t.index ["company_id", "tipo"], name: "index_ncf_sequences_on_company_id_and_tipo"
    t.index ["company_id"], name: "index_ncf_sequences_on_company_id"
    t.index ["rnc", "tipo"], name: "index_ncf_sequences_on_rnc_and_tipo"
  end

  create_table "ncf_usages", force: :cascade do |t|
    t.string "rnc", null: false
    t.string "encf", null: false
    t.string "track_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rnc", "encf"], name: "index_ncf_usages_on_rnc_and_encf"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_roles_on_deleted_at"
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "simulation_rules", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "rule_type", null: false
    t.boolean "active", default: true, null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["active"], name: "index_simulation_rules_on_active"
    t.index ["deleted_at"], name: "index_simulation_rules_on_deleted_at"
    t.index ["rule_type"], name: "index_simulation_rules_on_rule_type"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.integer "role_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "rnc"
    t.string "username"
    t.string "password_digest"
    t.integer "company_id"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["rnc", "username"], name: "index_users_on_rnc_and_username", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "validation_errors", force: :cascade do |t|
    t.integer "electronic_invoice_id", null: false
    t.string "codigo", null: false
    t.string "campo", null: false
    t.text "mensaje", null: false
    t.string "severidad", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["codigo"], name: "index_validation_errors_on_codigo"
    t.index ["deleted_at"], name: "index_validation_errors_on_deleted_at"
    t.index ["electronic_invoice_id"], name: "index_validation_errors_on_electronic_invoice_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object", limit: 1073741823
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "auth_tokens", "users"
  add_foreign_key "certificates", "companies"
  add_foreign_key "electronic_invoices", "companies"
  add_foreign_key "ncf_annulled_ranges", "ncf_annulations"
  add_foreign_key "ncf_sequences", "companies"
  add_foreign_key "users", "companies"
  add_foreign_key "users", "roles"
  add_foreign_key "validation_errors", "electronic_invoices"
end
