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
