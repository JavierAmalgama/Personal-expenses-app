class CategorySerializer < ActiveModel::Serializer
    attributes :id, :name, :kind, :parent_id
end
