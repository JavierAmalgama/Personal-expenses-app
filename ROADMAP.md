# Roadmap de la capacitación

User stories sugeridas, en orden. Cada una con su migración, modelo, serializer, swagger
definition, endpoints y specs (modelo, serializer y request).

## 1. Usuarios y sesión
- **US1** Como visitante quiero registrarme con nombre, email y contraseña (`has_secure_password`, bcrypt).
- **US2** Como usuario quiero iniciar sesión y recibir un token con vencimiento; y cerrar sesión (revocar el token).
- **US3** Como usuario quiero ver y editar mi perfil (`GET/PATCH /me`). `GET /users` deja de ser público.
- **US4** Como usuario quiero elegir mi moneda principal.

## 2. Cuentas
- **US5** CRUD de cuentas (`Account`: nombre, tipo `cash | bank | credit_card | savings`, moneda, saldo inicial).
- **US6** Cada usuario solo ve y modifica sus propias cuentas (scoping por `@logged_user`, `404` si no es suya).
- **US7** Archivar una cuenta en vez de borrarla si tiene movimientos.

## 3. Categorías
- **US8** CRUD de categorías por usuario (`Category`: nombre, tipo `income | expense`, color/ícono).
- **US9** Categorías por defecto al registrarse (Supermercado, Alquiler, Sueldo, …).
- **US10** Subcategorías (`parent_id`), validando que no haya ciclos.

## 4. Movimientos
- **US11** Registrar ingresos y gastos (`Transaction`: cuenta, categoría, monto en **centavos** como entero, fecha, descripción).
- **US12** El saldo de cada cuenta se calcula a partir del saldo inicial y sus movimientos.
- **US13** Listar movimientos con filtros (cuenta, categoría, rango de fechas, texto) y paginación.
- **US14** Editar y borrar movimientos.
- **US15** Transferencias entre cuentas propias (dos movimientos ligados, atómicos en una transacción de DB).

## 5. Presupuestos y reportes
- **US16** Presupuesto mensual por categoría (`Budget`) y su consumo actual.
- **US17** Resumen mensual: total ingresos, gastos y balance.
- **US18** Gastos agrupados por categoría en un rango de fechas.
- **US19** Evolución mensual de los últimos N meses.

## 6. Robustez
- **US20** Movimientos recurrentes (alquiler, suscripciones) generados por un job.
- **US21** Importar movimientos desde CSV del banco, detectando duplicados.
- **US22** Multi-moneda: tipo de cambio por movimiento y reportes en la moneda principal.
- **US23** Etiquetas (`Tag`) muchos-a-muchos con movimientos.
- **US24** Adjuntar comprobantes (Active Storage).
- **US25** Exportar a CSV.
- **US26** Índices, N+1 (Bullet), rate limiting y auditoría de cambios.
