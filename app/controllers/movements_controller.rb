class MovementsController < ApplicationController
    def index
        render_collection filtered_movements
    end

    def show
        render_object movement
    end

    def create
        render_created @logged_user.movements.create!(movement_params)
    end

    def update
        movement.update!(movement_params)
        render_object movement
    end

    def destroy
        movement.destroy!
        head :no_content
    end

    private

    def movement
        @movement ||= @logged_user.movements.find(params[:id])
    end

    def filtered_movements
        movements = @logged_user.movements.order(date: :desc, id: :desc)
        movements = movements.in_month(parsed_month) if params[:month].present?
        movements = movements.with_category(params[:category]) if params[:category].present?
        movements = movements.of_kind(validated_kind) if params[:kind].present?
        movements
    end

    def parsed_month
        Date.strptime(params[:month], "%Y-%m")
    rescue Date::Error
        raise InvalidParameterError.new("month must have the format YYYY-MM", details: { month: params[:month] })
    end

    def validated_kind
        return params[:kind] if Movement.kinds.key?(params[:kind])

        raise InvalidParameterError.new("kind must be one of: #{Movement.kinds.keys.join(', ')}",
            details: { kind: params[:kind] })
    end

    def movement_params
        params.permit(:kind, :date, :description, :amount, :currency, :category,
            :subcategory, :payment_method, :credit_card, :beneficiary, :notes, :shared)
    end
end
