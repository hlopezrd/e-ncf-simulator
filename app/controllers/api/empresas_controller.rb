module Api
  class EmpresasController < ApplicationController
    before_action :authenticate_request!
    include RoleAuthorization

    def index
      return if performed?

      companies = Company.where(deleted_at: nil).order(:rnc)
      data = companies.map do |c|
        total_ecf = ElectronicInvoice.where(company_id: c.id).count
        ultima = ElectronicInvoice.where(company_id: c.id).maximum(:fecha_recepcion)
        cert = c.certificates.where(active: true).order(created_at: :desc).first
        {
          id: c.id,
          rnc: c.rnc,
          razonSocial: c.razon_social,
          nombreComercial: c.nombre_comercial,
          email: c.email,
          telefono: c.telefono,
          activa: c.activa,
          totalEcf: total_ecf,
          ultimaRecepcion: ultima&.iso8601,
          certificadoVigente: cert&.vigente?,
          rangosActivos: c.ncf_sequences.where(activa: true).count
        }
      end

      render json: { data: data, meta: { total: data.size } }
    end

    def show
      return if performed?
      company = Company.find_by(id: params[:id])
      return render_not_found unless company
      render json: { data: serialize(company) }
    end

    def create
      return if performed?
      company = Company.new(company_params)
      if company.save
        audit!("create_company", "Company##{company.id}", { rnc: company.rnc }.to_json)
        render json: { data: serialize(company) }, status: :created
      else
        render json: { errors: company.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      return if performed?
      company = Company.find_by(id: params[:id])
      return render_not_found unless company
      if company.update(company_params)
        audit!("update_company", "Company##{company.id}", { rnc: company.rnc }.to_json)
        render json: { data: serialize(company) }
      else
        render json: { errors: company.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      return if performed?
      company = Company.find_by(id: params[:id])
      return render_not_found unless company
      company.destroy
      audit!("destroy_company", "Company##{company.id}", { rnc: company.rnc }.to_json)
      render json: { message: "Empresa eliminada" }
    end

    def certificados
      return if performed?
      company = Company.find_by(id: params[:id])
      return render_not_found unless company
      file = params[:file]
      return render json: { error: "Archivo requerido" }, status: :unprocessable_entity unless file

      pem = file.read
      alias_name = params[:alias]
      cert = Certificate.new(rnc: company.rnc, company: company, alias_name: alias_name, certificate_pem: pem, active: true)
      Certificate.transaction do
        Certificate.where(rnc: company.rnc, active: true).update_all(active: false)
        cert.save!
      end
      audit!("register_certificate", "Certificate##{cert.id}", { rnc: company.rnc }.to_json)
      render json: { data: { id: cert.id, thumbprint: cert.thumbprint, vigente: cert.vigente? } }, status: :created
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def ncf_sequences
      return if performed?
      company = Company.find_by(id: params[:id])
      return render_not_found unless company
      seq = NcfSequence.create!(
        rnc: company.rnc,
        company: company,
        tipo: params[:tipo].to_i,
        desde: params[:desde].to_i,
        hasta: params[:hasta].to_i,
        fecha_vencimiento: Date.parse(params[:vencimiento].to_s),
        activa: true
      )
      audit!("create_ncf_sequence", "NcfSequence##{seq.id}", { rnc: company.rnc, tipo: seq.tipo }.to_json)
      render json: { data: { id: seq.id, rnc: seq.rnc, tipo: seq.tipo, desde: seq.desde, hasta: seq.hasta } }, status: :created
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def estado_onboarding
      return if performed?
      company = Company.find_by(id: params[:id])
      return render_not_found unless company
      cert = company.certificates.where(active: true).order(created_at: :desc).first
      render json: {
        data: {
          companyId: company.id,
          rnc: company.rnc,
          certificadoRegistrado: cert.present?,
          certificadoVigente: cert&.vigente?,
          thumbprint: cert&.thumbprint,
          rangosActivos: company.ncf_sequences.where(activa: true).count,
          totalEcf: ElectronicInvoice.where(company_id: company.id).count
        }
      }
    end

    private

    def company_params
      params.permit(:rnc, :razon_social, :nombre_comercial, :email, :telefono, :activa)
    end

    def serialize(company)
      {
        id: company.id,
        rnc: company.rnc,
        razonSocial: company.razon_social,
        nombreComercial: company.nombre_comercial,
        email: company.email,
        telefono: company.telefono,
        activa: company.activa
      }
    end

    def render_not_found
      render json: { error: "Empresa no encontrada" }, status: :not_found
    end
  end
end