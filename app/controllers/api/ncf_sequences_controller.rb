module Api
  class NcfSequencesController < ApplicationController
    before_action :authenticate_request!
    include RoleAuthorization
    before_action -> { require_roles(:admin) }, only: [ :create, :update, :destroy ]

    def index
      return if performed?
      records = NcfSequence.order(created_at: :desc)
      render json: {
        data: records.map { |s| seq_json(s) },
        meta: { total: records.size }
      }
    end

    def create
      return if performed?
      record = NcfSequence.new(
        rnc: params[:rnc],
        tipo: params[:tipo],
        desde: params[:desde],
        hasta: params[:hasta],
        fecha_vencimiento: params[:fecha_vencimiento],
        activa: params.key?(:activa) ? params[:activa] : true
      )

      if record.save
        audit!("create_ncf_sequence", "NcfSequence##{record.id}", { rnc: record.rnc, tipo: record.tipo, desde: record.desde, hasta: record.hasta }.to_json)
        render json: seq_json(record), status: :created
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      return if performed?
      record = NcfSequence.find(params[:id])
      if record.update(
        rnc: params.key?(:rnc) ? params[:rnc] : record.rnc,
        tipo: params.key?(:tipo) ? params[:tipo] : record.tipo,
        desde: params.key?(:desde) ? params[:desde] : record.desde,
        hasta: params.key?(:hasta) ? params[:hasta] : record.hasta,
        fecha_vencimiento: params.key?(:fecha_vencimiento) ? params[:fecha_vencimiento] : record.fecha_vencimiento,
        activa: params.key?(:activa) ? params[:activa] : record.activa
      )
        render json: seq_json(record)
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "No encontrado" }, status: :not_found
    end

    def destroy
      return if performed?
      record = NcfSequence.find(params[:id])
      audit!("destroy_ncf_sequence", "NcfSequence##{record.id}", { rnc: record.rnc, tipo: record.tipo }.to_json)
      record.destroy
      head :no_content
    rescue ActiveRecord::RecordNotFound
      render json: { error: "No encontrado" }, status: :not_found
    end

    private

    def seq_json(s)
      {
        id: s.id,
        rnc: s.rnc,
        tipo: s.tipo,
        desde: s.desde,
        hasta: s.hasta,
        fechaVencimiento: s.fecha_vencimiento&.iso8601,
        activa: s.activa,
        vigente: s.vigente?,
        createdAt: s.created_at.iso8601,
        deletedAt: s.deleted_at&.iso8601
      }
    end
  end
end
