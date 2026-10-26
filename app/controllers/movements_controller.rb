class MovementsController < ApplicationController
    def index
        render_collection filtered_movements
    end

    def show
        render_object movement
    end

    def create
        render_object @logged_user.movements.create!(movement_params)
    end

    def update
        movement.update!(movement_params)
        render_object movement
    end

    def destroy
        movement.destroy!
        render_empty_successful_response
    end

    private

    def movement
        @movement ||= @logged_user.movements.find(params[:id])
    end

    def filtered_movements
        movements = @logged_user.movements.order(date: :desc, id: :desc)
        movements = movements.in_month(Date.strptime(params[:month], "%Y-%m")) if params[:month].present?
        movements = movements.with_category(params[:category]) if params[:category].present?
        movements = movements.of_kind(validated_kind) if params[:kind].present?
        movements
    end

    def validated_kind
        return params[:kind] if Movement.kinds.key?(params[:kind])

        raise ArgumentError, "kind must be one of: #{Movement.kinds.keys.join(', ')}"
    end

    def movement_params
        params.permit(:kind, :date, :description, :amount, :currency, :category,
            :subcategory, :payment_method, :credit_card, :beneficiary, :notes, :shared)
    end
end
