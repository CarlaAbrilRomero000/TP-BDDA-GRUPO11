# Verificación del Juego de Datos (Criterios de Aceptación)

**Sistema de Gestión para Parques Nacionales — Grupo 11**

Este documento indica, para cada punto que pide la consigna (sección IV — Criterios de Aceptación),
la consulta `SELECT` que permite verificarlo y el resultado esperado tras correr los scripts de carga.

**Orden de ejecución previo:** scripts `01`–`11`, luego `13-ScriptSeedData.sql` y
`13-ScriptSeed_ImportacionErrores.sql`.

```sql
USE ParquesNacionalesDB;
```

---

## 1. Cantidades mínimas exigidas

> Al menos 10 parques, 30 actividades/tours, 20 guías, 20 guardaparques, 10 concesiones.

Consulta única que muestra cada entidad contra su mínimo:

```sql
SELECT 'Parques'        AS entidad, COUNT(*) AS cantidad, 10 AS minimo FROM parques.Parque
UNION ALL SELECT 'Tours',          COUNT(*), 30 FROM turismo.AtraccionTour
UNION ALL SELECT 'Guías',          COUNT(*), 20 FROM turismo.Guia
UNION ALL SELECT 'Guardaparques',  COUNT(*), 20 FROM personal.Guardaparque
UNION ALL SELECT 'Concesiones',    COUNT(*), 10 FROM comercial.Concesion;
```

**Resultado esperado:** `cantidad >= minimo` en todas las filas.

| entidad | cantidad | minimo |
|---------|---------:|-------:|
| Parques | 10 | 10 |
| Tours | 30 | 30 |
| Guías | 20 | 20 |
| Guardaparques | 21 | 20 |
| Concesiones | 10 | 10 |

> El conteo de guardaparques puede ser mayor al mínimo si ya había datos previos en la base.

---

## 2. Historial de ventas de entradas

```sql
SELECT COUNT(*) AS tickets        FROM ventas.Ticket;
SELECT COUNT(*) AS detalle_ventas FROM ventas.TicketDetalle;
```

Detalle del historial (cabecera + líneas):

```sql
SELECT t.id_ticket, t.fecha_venta, t.total,
       td.id_parque, td.id_atraccion_tour, td.id_historial_precio,
       td.cantidad, td.precio_unitario, td.subtotal
FROM ventas.Ticket t
JOIN ventas.TicketDetalle td ON td.id_ticket = t.id_ticket
ORDER BY t.id_ticket, td.id_detalle;
```

**Resultado esperado:** existen tickets con sus líneas de detalle (entradas y tours).
Con el seed: **13 tickets / 17 líneas de detalle**.

---

## 3. Caso obligatorio 1 — Parque con múltiples actividades simultáneas

Un parque (`SEED-PN01`) con varios tours vendidos para la **misma fecha de acceso**:

```sql
SELECT td.fecha_acceso,
       COUNT(DISTINCT td.id_atraccion_tour) AS actividades_simultaneas
FROM ventas.TicketDetalle td
JOIN parques.Parque p ON p.id_parque = td.id_parque
WHERE p.codigo_oficial = 'SEED-PN01' AND td.id_atraccion_tour IS NOT NULL
GROUP BY td.fecha_acceso
HAVING COUNT(DISTINCT td.id_atraccion_tour) > 1;
```

**Resultado esperado:** al menos una fecha con más de una actividad.

| fecha_acceso | actividades_simultaneas |
|--------------|------------------------:|
| 2026-03-20 | 5 |

Para ver las actividades del parque:

```sql
SELECT at.id_atraccion_tour, at.nombre, at.cupo_maximo
FROM turismo.AtraccionTour at
JOIN parques.Parque p ON p.id_parque = at.id_parque
WHERE p.codigo_oficial = 'SEED-PN01';
```

---

## 4. Caso obligatorio 2 — Tour con cupo completo

El tour "Tour Demo Cupo Completo" tiene vendidas tantas plazas como su `cupo_maximo`:

```sql
SELECT at.nombre,
       at.cupo_maximo,
       SUM(td.cantidad) AS vendido,
       CASE WHEN SUM(td.cantidad) >= at.cupo_maximo
            THEN 'CUPO COMPLETO' ELSE 'con lugar' END AS estado
FROM turismo.AtraccionTour at
JOIN ventas.TicketDetalle td ON td.id_atraccion_tour = at.id_atraccion_tour
WHERE at.nombre = 'Tour Demo Cupo Completo'
GROUP BY at.nombre, at.cupo_maximo;
```

**Resultado esperado:** `vendido = cupo_maximo` y estado `CUPO COMPLETO`.

| nombre | cupo_maximo | vendido | estado |
|--------|------------:|--------:|--------|
| Tour Demo Cupo Completo | 10 | 10 | CUPO COMPLETO |

---

## 5. Caso obligatorio 3 — Concesión vigente y vencida

Se clasifica cada concesión por su `fecha_fin` respecto de la fecha actual:

```sql
SELECT CASE WHEN fecha_fin >= CAST(GETDATE() AS DATE)
            THEN 'VIGENTE' ELSE 'VENCIDA' END AS situacion,
       COUNT(*) AS cantidad
FROM comercial.Concesion
GROUP BY CASE WHEN fecha_fin >= CAST(GETDATE() AS DATE)
              THEN 'VIGENTE' ELSE 'VENCIDA' END;
```

**Resultado esperado:** al menos una vigente y una vencida.

| situacion | cantidad |
|-----------|---------:|
| VIGENTE | 6 |
| VENCIDA | 4 |

Listado detallado:

```sql
SELECT id_concesion, id_parque, tipo_actividad, fecha_inicio, fecha_fin,
       CASE WHEN fecha_fin >= CAST(GETDATE() AS DATE)
            THEN 'VIGENTE' ELSE 'VENCIDA' END AS situacion
FROM comercial.Concesion
ORDER BY fecha_fin;
```

---

## 6. Caso obligatorio 4 — Importación con errores parciales

Tras ejecutar `13-ScriptSeed_ImportacionErrores.sql` (que importa
`seed_visitantes_errores.csv`, previamente copiado a `C:\Importaciones\`).

### 6.a Filas inválidas registradas

```sql
SELECT fecha_error, motivo_error,
       indice_tiempo_valor, region_destino_valor,
       origen_visitantes_valor, visitas_valor
FROM estadisticas.ErroresImportacion
WHERE archivo_origen LIKE '%seed_visitantes_errores.csv'
ORDER BY id_error DESC;
```

**Resultado esperado:** 5 filas rechazadas, una por cada motivo.

| motivo_error | valor problemático |
|--------------|--------------------|
| La región de destino es nula o vacía. | región vacía |
| La cantidad de visitas no es un valor numérico válido. | `muchos` |
| La cantidad de visitas no puede ser negativa. | `-50` |
| La fecha (indice_tiempo) es inválida o está vacía. | `ABCD` |
| Registro duplicado dentro del archivo. | clave repetida |

### 6.b Filas válidas cargadas

```sql
SELECT indice_tiempo, region_destino, origen_visitantes, visitas, observaciones
FROM estadisticas.VisitantesParques
WHERE region_destino IN ('Patagonia', 'Litoral', 'Cuyo')
ORDER BY indice_tiempo, region_destino, origen_visitantes;
```

**Resultado esperado:** **4 filas** insertadas (las válidas del archivo). La importación además
devuelve el resumen: `registros_insertados = 4`, `registros_actualizados = 0`,
`registros_rechazados = 5`.

---

## Resumen

| Criterio | Estado |
|----------|:------:|
| 10 parques | ✅ |
| 30 actividades/tours | ✅ |
| 20 guías | ✅ |
| 20 guardaparques | ✅ |
| 10 concesiones | ✅ |
| Historial de ventas de entradas | ✅ |
| Caso 1 — actividades simultáneas | ✅ |
| Caso 2 — tour con cupo completo | ✅ |
| Caso 3 — concesión vigente y vencida | ✅ |
| Caso 4 — importación con errores parciales | ✅ |
