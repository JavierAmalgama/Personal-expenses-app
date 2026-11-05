class CategoriesController < ApplicationController
    def index
        categories = @logged_user.categories.order(:name)
        categories = categories.where(kind: validated_kind) if params[:kind].present?
        render_collection categories
    end

    private

    def validated_kind
        return params[:kind] if Category.kinds.key?(params[:kind])

        raise InvalidParameterError.new("kind must be one of: #{Category.kinds.keys.join(', ')}",
            details: { kind: params[:kind] })
    end
end
