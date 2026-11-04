# finances-back

API Rails 7.1 (modo API) + PostgreSQL para una herramienta de seguimiento de gastos personales.
Es el punto de partida de la capacitación de backend: trae la infraestructura armada
(autenticación por token, helpers de render, manejo de errores, RSpec + rswag + FactoryBot)
y solo los modelos `User` y `UsersToken`. El dominio de finanzas se construye siguiendo
[ROADMAP.md](ROADMAP.md).

## Requisitos

- Ruby 3.1.4 (`rbenv`)
- PostgreSQL

## Setup

```bash
eval "$(rbenv init - zsh)"
bundle install
cp .env.example .env          # completar con las credenciales de tu Postgres
bin/rails db:prepare db:seed
```

El seed crea el usuario `demo@finances.test` con el token `dev-token-123!` (no vence),
configurable con `DEV_API_TOKEN`.

## Correr

```bash
bin/rails server -b 0.0.0.0   # 0.0.0.0 para que lleguen el emulador Android y celulares
```

- `GET /up` — health check (sin token)
- `GET /api-docs` — Swagger UI
- El resto de los endpoints exige el header `Authorization: <token>`:
  sin header → `401`, token inexistente o vencido → `403`.

CORS permite cualquier puerto de `localhost` (`config/initializers/cors.rb`) para el front web.

## Tests y documentación

```bash
bundle exec rspec
bin/rails rswag:specs:swaggerize   # regenera swagger/v1/swagger.json desde los specs de requests
```

## Estructura y convenciones

```
app/controllers/application_controller.rb    validate_token + rescue_from de errores comunes
app/controllers/concerns/rendering_helpers.rb render_object / render_collection / render_error
app/models/application_record.rb             #serialize (ActiveModelSerializers)
app/serializers/                             un serializer por modelo
swagger/definitions/                         schema de cada modelo para rswag (<modelo>_definition)
spec/requests/                               specs de rswag: documentan y testean cada endpoint
spec/shared_contexts|shared_examples/        "with valid token", "requires authorization"
spec/support/requests.rb                     send_request, expect_object_response, schemas
```

Para cada recurso nuevo: migración → modelo + validaciones → factory + spec de modelo →
serializer + spec → swagger definition → controller + ruta → spec de request.

Errores: `RecordInvalid` → `422 invalid_record`, `RecordNotFound` → `404 record_not_found`,
`ArgumentError` → `422 invalid_argument`, con el formato
`{ "response": { "error_name": ..., "error_message": ... } }`.

## Modelo de datos

```mermaid
erDiagram
    users ||--o{ users_tokens : "se autentica con"
    users ||--o{ movements : registra
    users ||--o{ categories : define
    users ||--o{ events : organiza
    users ||--o| user_settings : configura
    categories ||--o{ categories : "subcategorías (parent_id)"
    categories ||--o{ movements : clasifica
    events ||--o{ movements : agrupa

    users {
        bigint id PK
        string name
        string email UK
    }
    users_tokens {
        bigint id PK
        bigint user_id FK
        string token UK
        datetime valid_until
    }
    categories {
        bigint id PK
        bigint user_id FK
        bigint parent_id FK "null = categoría raíz"
        string name "único por (user_id, parent_id)"
        string kind "income | expense"
    }
    events {
        bigint id PK
        bigint user_id FK
        string name
    }
    movements {
        bigint id PK
        bigint user_id FK
        bigint category_id FK "nullable"
        bigint event_id FK "nullable"
        string kind "income | expense"
        date date
        string description
        decimal amount "12,2"
        string currency "ARS | USD"
        string payment_method
        string credit_card
        string beneficiary
        text notes
        boolean shared
    }
    user_settings {
        bigint id PK
        bigint user_id FK,UK
        decimal monthly_budget "12,2"
        string budget_currency
    }
```

### Normalización: de dónde venimos

La primera versión de `movements` guardaba la categoría como texto:

| id | user_id | description | category | subcategory |
|----|---------|-------------|----------|-------------|
| 2 | 1 | Alquiler octubre | Vivienda | Alquiler |
| 5 | 1 | Expensas | Vivienda | Expensas |
| 6 | 1 | Alquiler noviembre | vivienda | Alquiler |

- **1FN** (valores atómicos, sin grupos repetidos): se cumplía, porque cada celda tiene un solo valor.
- **2FN** (cada columna depende de toda la clave): se cumplía, porque la clave es `id`, simple.
- **3FN** (sin dependencias transitivas): **no se cumplía**. Que "Alquiler" sea hija de "Vivienda" y que sea un gasto son hechos de la *categoría*, no del movimiento, pero se repetían en cada fila. Eso provoca anomalías:
  - **De actualización:** renombrar "Vivienda" obliga a tocar todos los movimientos, y si se escapa uno quedan dos categorías.
  - **De inserción:** no se puede crear una categoría sin tener un movimiento.
  - **De consistencia:** "Vivienda" y "vivienda" pasan a ser categorías distintas.

Ahora la categoría es una entidad (`categories`) y el movimiento solo guarda `category_id`.

### Decisiones

- **`categories` en tabla propia, por usuario y con `parent_id`.** La taxonomía es configurable por cada usuario, así que la tabla lleva `user_id`. Las subcategorías se resuelven con autorreferencia, con un solo nivel validado en el modelo. El índice único `(user_id, parent_id, name)` con `NULLS NOT DISTINCT` hace que Postgres tampoco acepte dos categorías raíz con el mismo nombre. El movimiento apunta a la categoría más específica (la subcategoría si la tiene) y la raíz se deriva por `parent`. Así se evita guardar `category_id` y `subcategory_id` juntos y que contradigan. Las "categorías aprendidas" del front son simplemente estas filas.
- **`kind` en la categoría y en el movimiento.** Puede parecer duplicado, pero cumplen roles distintos: el del movimiento define el signo del monto y el de la categoría define en qué listas aparece. El modelo valida que coincidan.
- **`events` como tabla.** Un viaje o un cumpleaños tiene identidad propia (nombre, y a futuro fechas o participantes) y agrupa muchos movimientos. Es una relación 1:N opcional, y si se borra el evento el `event_id` queda en `NULL` (`on_delete: :nullify`).
- **`user_settings` 1:1 en vez de columnas en `users`.** Separa la identidad (users) de las preferencias, y las columnas quedan tipadas y validables. La unicidad de `user_id` garantiza el 1:1 en la base.
- **`payment_method` y `credit_card` como strings con enum de Rails, por ahora.** Son listas fijas que no cambian por usuario, así que no ganan nada siendo una tabla. En la sesión 5 se evalúa pasarlas a enums de Postgres.
- **FKs con `on_delete`.** `cascade` para lo que pertenece al usuario y `nullify` para referencias opcionales (categoría y evento del movimiento). La base mantiene la integridad aunque se borre por fuera de Rails.

### Migraciones reversibles

Todas se pueden revertir con `bin/rails db:rollback`:

| Migración | Cómo revierte |
|-----------|---------------|
| `CreateCategories`, `AddCategoryToMovements`, `CreateEvents`, `CreateUserSettings` | `change`: Rails infiere la inversa (`drop_table`, `remove_reference`). |
| `MoveMovementCategoriesToTable` | `up`/`down` explícitos. Es una migración de datos en SQL que Rails no puede invertir solo: `up` crea las categorías a partir de los strings y llena `category_id`, y `down` reconstruye los strings desde el join. |
| `RemoveCategoryStringsFromMovements` | `change`, pasando el tipo en `remove_column` y las columnas en `remove_index` para que Rails sepa recrearlas. |

Verificado con datos: `db:rollback STEP=6` deja los strings de categoría idénticos a los originales, y volver a migrar reproduce el mismo `schema.rb`. La única diferencia después del rollback es el **orden** de las columnas `category`/`subcategory`, porque Postgres las agrega al final de la tabla. No cambia nada funcional.
