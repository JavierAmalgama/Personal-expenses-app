# Sesión 5 — EXPLAIN ANALYZE de los índices de `movements`

Datos: `bin/rails "perf:seed_movements[200000]"` → 220.009 movimientos en 20 usuarios (~11.000 cada uno), PostgreSQL 18. El usuario medido es `perf-0@finances.test` (`user_id = 2`).

Las consultas son las que genera la app (`.to_sql`):

- **Q1, filtro por mes** (`GET /movements?month=2026-10`): `user.movements.in_month(...).order(date: :desc, id: :desc)`
- **Q2, últimos 50** (listado sin filtro): `user.movements.order(date: :desc, id: :desc).limit(50)`
- **Q3, reintegros de un gasto:** `Movement.offsetting("movement", id)`
- **Q4, baja cardinalidad:** `SELECT count(*) FROM movements WHERE kind = 'expense'`

Para medir "sin índice" sin tocar las migraciones se usa que el DDL de Postgres es transaccional:

```sql
BEGIN;
DROP INDEX index_movements_on_user_id_and_date;
EXPLAIN (ANALYZE, BUFFERS) <query>;
ROLLBACK;  -- el índice vuelve
```

## Resumen

| Consulta | Con índice | Sin índice | Con solo `(user_id)` |
|----------|-----------|------------|----------------------|
| Q1 mes | **2,2 ms**, Bitmap Index Scan `(user_id, date)`, 270 páginas | 17,4 ms, Parallel Seq Scan, 3.430 páginas | 2,3 ms, pero 3.223 páginas: filtra la fecha descartando 10.720 filas |
| Q2 últimos 50 | **0,05 ms**, Index Scan Backward, 58 páginas | 11,3 ms, Seq Scan + top-N sort | 3,0 ms, lee y ordena los 10.993 movimientos del usuario |
| Q3 `@>` | **1,9 ms**, Bitmap Index Scan GIN | 6,0 ms, Parallel Seq Scan | — |
| Q4 `kind` | — | 5,7 ms Seq Scan **aunque exista** un índice en `kind` | — |

Los tiempos de Q1 con el compuesto y con solo `(user_id)` son parecidos porque toda la tabla está en memoria (`shared hit`). La diferencia real son las páginas leídas (270 vs 3.223): en una base con datos fuera de caché, eso es lectura de disco.

## Planes completos

```
=== Q1 month filter WITH (user_id, date) ===
                                                                       QUERY PLAN                                                                        
---------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=845.87..846.54 rows=270 width=216) (actual time=1.979..2.000 rows=273.00 loops=1)
   Sort Key: date DESC, id DESC
   Sort Method: quicksort  Memory: 53kB
   Buffers: shared hit=270
   ->  Bitmap Heap Scan on movements  (cost=7.86..834.96 rows=270 width=216) (actual time=0.479..1.726 rows=273.00 loops=1)
         Recheck Cond: ((user_id = 2) AND (date >= '2026-10-01'::date) AND (date <= '2026-10-31'::date))
         Heap Blocks: exact=258
         Buffers: shared hit=264
         ->  Bitmap Index Scan on index_movements_on_user_id_and_date  (cost=0.00..7.79 rows=270 width=0) (actual time=0.401..0.401 rows=273.00 loops=1)
               Index Cond: ((user_id = 2) AND (date >= '2026-10-01'::date) AND (date <= '2026-10-31'::date))
               Index Searches: 1
               Buffers: shared hit=6
 Planning:
   Buffers: shared hit=206
 Planning Time: 1.938 ms
 Execution Time: 2.158 ms
(16 rows)

=== Q1 month filter WITHOUT any user index ===
                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=5948.07..5979.40 rows=269 width=216) (actual time=15.138..17.410 rows=273.00 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=3430
   ->  Sort  (cost=4948.04..4948.32 rows=112 width=216) (actual time=9.964..9.969 rows=91.00 loops=3)
         Sort Key: date DESC, id DESC
         Sort Method: quicksort  Memory: 38kB
         Buffers: shared hit=3430
         Worker 0:  Sort Method: quicksort  Memory: 31kB
         Worker 1:  Sort Method: quicksort  Memory: 33kB
         ->  Parallel Seq Scan on movements  (cost=0.00..4944.23 rows=112 width=216) (actual time=0.067..9.833 rows=91.00 loops=3)
               Filter: ((date >= '2026-10-01'::date) AND (date <= '2026-10-31'::date) AND (user_id = 2))
               Rows Removed by Filter: 73245
               Buffers: shared hit=3340
 Planning:
   Buffers: shared hit=5
 Planning Time: 0.109 ms
 Execution Time: 17.446 ms
(18 rows)

=== Q2 latest 50 of user WITHOUT any user index ===
                                                                 QUERY PLAN                                                                 
--------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=5637.55..5643.37 rows=50 width=216) (actual time=9.568..11.284 rows=50.00 loops=1)
   Buffers: shared hit=3430
   ->  Gather Merge  (cost=5637.55..6913.56 rows=10956 width=216) (actual time=9.567..11.278 rows=50.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=3430
         ->  Sort  (cost=4637.53..4648.94 rows=4565 width=216) (actual time=7.107..7.117 rows=40.00 loops=3)
               Sort Key: date DESC, id DESC
               Sort Method: top-N heapsort  Memory: 37kB
               Buffers: shared hit=3430
               Worker 0:  Sort Method: top-N heapsort  Memory: 37kB
               Worker 1:  Sort Method: top-N heapsort  Memory: 37kB
               ->  Parallel Seq Scan on movements  (cost=0.00..4485.88 rows=4565 width=216) (actual time=0.011..6.405 rows=3664.33 loops=3)
                     Filter: (user_id = 2)
                     Rows Removed by Filter: 69672
                     Buffers: shared hit=3340
 Planning Time: 0.087 ms
 Execution Time: 11.305 ms
(18 rows)

=== Q1 month filter with ONLY (user_id) (the removed index) ===
                                                               QUERY PLAN                                                                
-----------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=3665.17..3665.84 rows=270 width=216) (actual time=2.306..2.313 rows=273.00 loops=1)
   Sort Key: date DESC, id DESC
   Sort Method: quicksort  Memory: 53kB
   Buffers: shared hit=3212 read=11
   ->  Bitmap Heap Scan on movements  (cost=122.53..3654.26 rows=270 width=216) (actual time=0.511..2.249 rows=273.00 loops=1)
         Recheck Cond: (user_id = 2)
         Filter: ((date >= '2026-10-01'::date) AND (date <= '2026-10-31'::date))
         Rows Removed by Filter: 10720
         Heap Blocks: exact=3212
         Buffers: shared hit=3212 read=11
         ->  Bitmap Index Scan on tmp_user_only  (cost=0.00..122.47 rows=10956 width=0) (actual time=0.288..0.288 rows=10993.00 loops=1)
               Index Cond: (user_id = 2)
               Index Searches: 1
               Buffers: shared read=11
 Planning:
   Buffers: shared hit=5 read=1
 Planning Time: 0.143 ms
 Execution Time: 2.329 ms
(18 rows)

=== Q2 latest 50 of user with ONLY (user_id) ===
                                                                  QUERY PLAN                                                                   
-----------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=3966.10..3966.23 rows=50 width=216) (actual time=2.978..2.982 rows=50.00 loops=1)
   Buffers: shared hit=3223
   ->  Sort  (cost=3966.10..3993.49 rows=10956 width=216) (actual time=2.978..2.979 rows=50.00 loops=1)
         Sort Key: date DESC, id DESC
         Sort Method: top-N heapsort  Memory: 39kB
         Buffers: shared hit=3223
         ->  Bitmap Heap Scan on movements  (cost=125.20..3602.15 rows=10956 width=216) (actual time=0.431..1.973 rows=10993.00 loops=1)
               Recheck Cond: (user_id = 2)
               Heap Blocks: exact=3212
               Buffers: shared hit=3223
               ->  Bitmap Index Scan on tmp_user_only  (cost=0.00..122.47 rows=10956 width=0) (actual time=0.235..0.236 rows=10993.00 loops=1)
                     Index Cond: (user_id = 2)
                     Index Searches: 1
                     Buffers: shared hit=11
 Planning Time: 0.030 ms
 Execution Time: 2.989 ms
(16 rows)

=== Q2 latest 50 of user WITH (user_id, date) ===
                                                                                    QUERY PLAN                                                                                    
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=12.85..76.47 rows=50 width=216) (actual time=0.031..0.043 rows=50.00 loops=1)
   Buffers: shared hit=58
   ->  Incremental Sort  (cost=12.85..13954.52 rows=10956 width=216) (actual time=0.030..0.041 rows=50.00 loops=1)
         Sort Key: date DESC, id DESC
         Presorted Key: date
         Full-sort Groups: 2  Sort Method: quicksort  Average Memory: 32kB  Peak Memory: 32kB
         Buffers: shared hit=58
         ->  Index Scan Backward using index_movements_on_user_id_and_date on movements  (cost=0.42..13614.43 rows=10956 width=216) (actual time=0.008..0.025 rows=52.00 loops=1)
               Index Cond: (user_id = 2)
               Index Searches: 1
               Buffers: shared hit=55
 Planning:
   Buffers: shared hit=21
 Planning Time: 0.101 ms
 Execution Time: 0.052 ms
(15 rows)

=== Q4 kind = expense with an index on kind (low cardinality) ===
                                                                 QUERY PLAN                                                                 
--------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=5663.64..5663.65 rows=1 width=8) (actual time=5.021..5.717 rows=1.00 loops=1)
   Buffers: shared hit=3340
   ->  Gather  (cost=5663.42..5663.63 rows=2 width=8) (actual time=4.982..5.714 rows=3.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=3340
         ->  Partial Aggregate  (cost=4663.42..4663.43 rows=1 width=8) (actual time=3.909..3.909 rows=1.00 loops=3)
               Buffers: shared hit=3340
               ->  Parallel Seq Scan on movements  (cost=0.00..4485.88 rows=71017 width=0) (actual time=0.005..2.800 rows=56799.00 loops=3)
                     Filter: (kind = 'expense'::movement_kind)
                     Rows Removed by Filter: 16537
                     Buffers: shared hit=3340
 Planning:
   Buffers: shared hit=15 read=1
 Planning Time: 0.046 ms
 Execution Time: 5.726 ms
(16 rows)

=== Q3 offset_data @> WITH GIN ===
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on movements  (cost=1385.79..1393.67 rows=2 width=216) (actual time=1.879..1.880 rows=1.00 loops=1)
   Recheck Cond: (offset_data @> '{"target_id": 185095, "target_type": "movement"}'::jsonb)
   Heap Blocks: exact=1
   Buffers: shared hit=325
   ->  Bitmap Index Scan on index_movements_on_offset_data  (cost=0.00..1385.79 rows=2 width=0) (actual time=1.876..1.876 rows=1.00 loops=1)
         Index Cond: (offset_data @> '{"target_id": 185095, "target_type": "movement"}'::jsonb)
         Index Searches: 1
         Buffers: shared hit=324
 Planning:
   Buffers: shared hit=64
 Planning Time: 0.080 ms
 Execution Time: 1.885 ms
(12 rows)

=== Q3 offset_data @> WITHOUT GIN ===
                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..5486.08 rows=2 width=216) (actual time=5.301..6.025 rows=1.00 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=3340
   ->  Parallel Seq Scan on movements  (cost=0.00..4485.88 rows=1 width=216) (actual time=4.086..4.342 rows=0.33 loops=3)
         Filter: (offset_data @> '{"target_id": 185095, "target_type": "movement"}'::jsonb)
         Rows Removed by Filter: 73336
         Buffers: shared hit=3340
 Planning:
   Buffers: shared hit=5
 Planning Time: 0.034 ms
 Execution Time: 6.028 ms
(12 rows)

```
