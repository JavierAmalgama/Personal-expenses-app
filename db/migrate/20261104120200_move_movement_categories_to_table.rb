class MoveMovementCategoriesToTable < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      INSERT INTO categories (user_id, parent_id, name, kind, created_at, updated_at)
      SELECT DISTINCT ON (user_id, category) user_id, NULL, category, kind, NOW(), NOW()
      FROM movements
      WHERE category IS NOT NULL
      ORDER BY user_id, category, id;

      INSERT INTO categories (user_id, parent_id, name, kind, created_at, updated_at)
      SELECT DISTINCT ON (m.user_id, m.category, m.subcategory) m.user_id, p.id, m.subcategory, p.kind, NOW(), NOW()
      FROM movements m
      JOIN categories p ON p.user_id = m.user_id AND p.parent_id IS NULL AND p.name = m.category
      WHERE m.subcategory IS NOT NULL
      ORDER BY m.user_id, m.category, m.subcategory, m.id;

      UPDATE movements m
      SET category_id = c.id
      FROM categories c
      WHERE c.user_id = m.user_id AND c.parent_id IS NULL AND c.name = m.category;

      UPDATE movements m
      SET category_id = s.id
      FROM categories s
      JOIN categories p ON p.id = s.parent_id
      WHERE s.user_id = m.user_id AND p.name = m.category AND s.name = m.subcategory;
    SQL
  end

  def down
    execute <<~SQL
      UPDATE movements m
      SET category = c.name, subcategory = NULL
      FROM categories c
      WHERE c.id = m.category_id AND c.parent_id IS NULL;

      UPDATE movements m
      SET category = p.name, subcategory = s.name
      FROM categories s
      JOIN categories p ON p.id = s.parent_id
      WHERE s.id = m.category_id;

      UPDATE movements SET category_id = NULL;
      DELETE FROM categories;
    SQL
  end
end
